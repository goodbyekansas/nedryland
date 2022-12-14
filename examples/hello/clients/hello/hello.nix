# greeting is automatically passed in
# since there is a component with the same name
{ base, greeting, writeScriptBin }:
base.mkClient rec{
  name = "hello";
  version = "1.0.0";
  package = ((writeScriptBin name ''
    set -e
    translation=$(${greeting.lib}/bin/greetinglib $1)
    echo "Hello in $1 is \"$translation\""
  '').overrideAttrs (_: {
    passthru.shellCommands = {
      # Because all shell commands becomes programs in path we can call
      # them from each other.
      hello = ''
        enableBlink
        echo "Hello!"
        stopBlink
      '';

      # You can specify the command by only supplying a string.
      # It won't have a description of course if you specify them like this.
      enableBlink = ''echo -e "\x1b[5;38;2;''${1:-255};''${2:-253};''${3:-125}m"'';
      stopBlink = ''echo -e "\x1b[0m"'';

      # Setting show to false will make it not be prompted when you enter the shell
      secret = {
        show = false;
        description = "You won't see this";
        script = ''
          enableBlink 174 156 255
          echo "You can run this but you won't see this command when you enter the shell"
          stopBlink
        '';
      };
    };
  }));

}
