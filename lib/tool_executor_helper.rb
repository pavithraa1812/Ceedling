require 'constants' # for Verbosity enumeration & $stderr redirect enumeration

class ToolExecutorHelper

  constructor :streaminator, :system_wrapper

  def background_exec_cmdline_prepend(tool_config)
    return nil if (tool_config[:background_exec].nil?)
    
    config_exec = tool_config[:background_exec]
    
    if ((config_exec == BackgroundExec::AUTO) and (@system_wrapper.is_windows?))
      return 'start'
    end

    if (config_exec == BackgroundExec::WIN)
      return 'start'
    end

    return nil
  end

  def osify_path_separators(executable)
    return executable.gsub(/\//, '\\') if (@system_wrapper.is_windows?)
    return executable
  end
  
  def background_exec_cmdline_addendum(tool_config)
    return nil if (tool_config[:background_exec].nil?)

    config_exec = tool_config[:background_exec]
    
    if ((config_exec == BackgroundExec::AUTO) and (not @system_wrapper.is_windows?))
      return '&'
    end

    if (config_exec == BackgroundExec::UNIX)
      return '&'
    end

    return nil
  end

  def stderr_redirect_cmdline_addendum(tool_config)
    return nil if (tool_config[:stderr_redirect].nil?)
    
    config_redirect = tool_config[:stderr_redirect]
    redirect        = StdErrRedirect::NONE
    
    if (config_redirect == StdErrRedirect::AUTO)
      redirect = ((@system_wrapper.is_windows?) ? StdErrRedirect::WIN : StdErrRedirect::UNIX)
    end
    
    case redirect
      # we may need more complicated processing after some learning with various environments
      when StdErrRedirect::NONE then nil
      when StdErrRedirect::WIN  then '2>&1'
      when StdErrRedirect::UNIX then '2>&1'
      when StdErrRedirect::TCSH then '|&'
      else redirect.to_s
    end
  end

  # if command succeeded and we have verbosity cranked up, spill our guts
  def print_happy_results(command_str, shell_result)
    if (shell_result[:exit_code] == 0)
      output  = "> Shell executed command:\n"
      output += "#{command_str}\n"
      output += "> Produced response:\n"           if (not shell_result[:output].empty?)
      output += "#{shell_result[:output].strip}\n" if (not shell_result[:output].empty?)
      output += "\n"
    
      @streaminator.stdout_puts(output, Verbosity::OBNOXIOUS)
    end
  end

  # if command failed and we have verbosity set to minimum error level, spill our guts
  def print_error_results(command_str, shell_result)
    if (shell_result[:exit_code] != 0)
      output  = "ERROR: Shell command failed.\n"
      output += "> Shell executed command:\n"
      output += "'#{command_str}'\n"
      output += "> Produced response:\n"           if (not shell_result[:output].empty?)
      output += "#{shell_result[:output].strip}\n" if (not shell_result[:output].empty?)
      output += "> And exited with status: [#{shell_result[:exit_code]}].\n" if (shell_result[:exit_code] != nil)
      output += "> And then likely crashed.\n"                               if (shell_result[:exit_code] == nil)
      output += "\n"

      @streaminator.stderr_puts(output, Verbosity::ERRORS)
    end
  end
  
end
