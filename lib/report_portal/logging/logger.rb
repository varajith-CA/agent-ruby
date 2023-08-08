require 'logger'

module ReportPortal
  class << self
    # Monkey-patch for built-in Logger class
    def patch_logger
      Logger.class_eval do
        alias_method :orig_add, :add
        alias_method :orig_write, :<<
        alias_method :orig_add_file, :add_file
        alias_method :orig_write_file, :<<
        def add(severity, message = nil, progname = nil, &block)
          ret = orig_add(severity, message, progname, &block)

          unless severity < @level
            progname ||= @progname
            if message.nil?
              if block_given?
                message = yield
              else
                message = progname
                progname = @progname
              end
            end
            ReportPortal.send_log(format_severity(severity), format_message(format_severity(severity), Time.now, progname, message.to_s), ReportPortal.now)
          end
          ret
        end

        def add_file(status, path_or_src, label = nil, time = ReportPortal.now, mime_type = 'image/png')
          ret = orig_add_file(status, path_or_src, label, time, mime_type)
          ReportPortal.send_file(status, path_or_src, label, time, mime_type)
          ret
        end

        def <<(msg)
          ret = orig_write(msg)
          ReportPortal.send_log(ReportPortal::LOG_LEVELS[:unknown], msg.to_s, ReportPortal.now)
          ret
        end

        def <<(path_or_src, label)
          ret = orig_write_file(path_or_src, label)
          ReportPortal.send_file(ReportPortal::LOG_LEVELS[:unknown], path_or_src, label, ReportPortal.now, mimime_type = 'image/png')
          ret
        end
      end
    end
  end
end
