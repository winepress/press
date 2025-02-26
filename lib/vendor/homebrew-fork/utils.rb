require 'pathname'
require 'vendor/homebrew-fork/exceptions'

def homebrew_fork_system cmd, *args
  puts "#{cmd} #{args*' '}" if Hbc.verbose
  pid = fork do
    yield if block_given?
    args.collect!{|arg| arg.to_s}
    exec(cmd, *args) rescue nil
    exit! 1 # never gets here unless exec failed
  end
  Process.wait(pid)
  $?.success?
end

# Kernel.system but with exceptions
def safe_system cmd, *args
  homebrew_fork_system(cmd, *args) or raise Hbc::ErrorDuringExecution.new(cmd, args)
end

# prints no output
def quiet_system cmd, *args
  homebrew_fork_system(cmd, *args) do
    # Redirect output streams to `/dev/null` instead of closing as some programs
    # will fail to execute if they can't write to an open stream.
    $stdout.reopen('/dev/null')
    $stderr.reopen('/dev/null')
  end
end

def curl *args
  curl = Pathname.new '/usr/bin/curl'
  raise "#{curl} is not executable" unless curl.exist? and curl.executable?

  flags = HOMEBREW_CURL_ARGS
  flags = flags.delete("#") if Hbc.verbose

  args = [flags, HOMEBREW_USER_AGENT, *args]
  # See https://github.com/Homebrew/homebrew/issues/6103
  args << "--insecure" if MacOS.release < "10.6"
  args << "--verbose" if ENV['HOMEBREW_CURL_VERBOSE']
  args << "--silent" unless $stdout.tty?

  safe_system curl, *args
end

def aria *args
  aria = Pathname.new '/usr/local/bin/aria2c'
  raise "#{aria} is not executable" unless aria.exist? and aria.executable?

  # flags = ''
  # flags = HOMEBREW_CURL_ARGS
  # flags = flags.delete("#") if Hbc.verbose

  args = *args
  # See https://github.com/Homebrew/homebrew/issues/6103
  # args << "--insecure" if MacOS.release < "10.6"
  # args << "--verbose" if ENV['HOMEBREW_CURL_VERBOSE']
  # args << "--silent" unless $stdout.tty?
  args << "--seed-time=0"
  args << "--allow-overwrite=true"

  puts args
  # puts args.length
  puts aria, *args
  safe_system aria, *args
  # safe_system aria, args[1]
end
