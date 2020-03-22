import 'package:dshell/dshell.dart';
import 'package:meta/meta.dart';

///
/// Provides remote access methods for posix based systems.
///
class Remote {
  /// EXPERIMENTAL
  ///
  /// executes command on a remote host over an ssh tunnel
  /// [host] is the remote host to execute the command on.
  /// If [sudo] is true then the command will be run with sudo.
  /// If you specify [sudo] as true then you MAY also pass in the
  /// sudo [password] for your account on the remote host.
  /// [password] is the current user's password on the remote host.
  ///   The user's account on the remote host must be in the sudoers file.
  /// The [command] to execute on the remote host.
  /// The optional [progress] allows you to control how the output
  /// of the command is printed to the console. By default all output is supressed.
  ///
  /// ```dart
  ///  // run mkdir on the remote host using sudo
  ///  Remote.exec(
  ///     host: fqdn,
  ///     command: "mkdir -p /tmp/etc/openvpn",
  ///     sudo: true,
  ///     password: password,
  ///     progress: Progress.print());
  /// ```
  ///
  ///  EXPERIMENTAL
  static void exec(
      {String host,
      String command,
      bool agent = true,
      bool sudo = false,
      String password,
      Progress progress}) {
    execList(
        host: host,
        commands: [command],
        agent: agent,
        sudo: sudo,
        password: password,
        progress: progress);
  }

  /// [execList] runs multiple commands in a single request to the host.
  ///
  /// The commands are chained into a single command line with the bash command delimiter ';'
  /// betwen each command.
  ///
  /// If you set [sudo] to true then each command is run under sudo.
  /// If you set [password] then the password is passed to the sudo command.
  ///
  /// ```dart
  ///   Remote.exec(
  ///     host: fqdn,
  ///     command: ['mkdir -p /tmp/dir/fred', 'cp /home/bsutton/*.dart /tmp/dir/fred', 'ls /tmp/dir/fred/*.dart'],
  ///     sudo: true,
  ///     password: password,
  ///     progress: Progress.print());
  /// ```
  ///
  static void execList(
      {String host,
      List<String> commands,
      bool agent = true,
      bool sudo = false,
      String password,
      Progress progress}) {
    var cmdArgs = <String>[];

    // enable agent forwarding only
    // if the user doesn't pass a password.
    if (agent && password == null) {
      cmdArgs.add('-A');
    }
    // disable psuedo terminal
    cmdArgs.add('-T');
    cmdArgs.add('$host');

    var cmdLine = '';
    for (var command in commands) {
      if (sudo) {
        // -S accept echoed password{
        // -k clear the sudo cached password so it expects a password
        // -p ''  blank out the password prompt give we are echoing the password in.
        // We quote the [command] to stop glob expansion on the local system.
        if (password != null) {
          command ="echo $password | sudo -Skp '' $command";
        } else {
          command = 'sudo $command';
        }
      }
      if (cmdLine.isNotEmpty) {
        // bash command delimiter.
        cmdLine += ';';
      }
      cmdLine += command;
    }

    cmdArgs.add('"$cmdLine"');

    progress ??= Progress.devNull();

    try {
      startFromArgs('ssh', cmdArgs, progress: progress);
    } on RunException catch (e) {
      var error = sshErrors[e.exitCode];
      throw RunException(
          e.cmdLine, e.exitCode, red('ssh exit code: ${e.exitCode} - $error'),
          stackTrace: e.stackTrace);
    }
  }

  /// Run scp (secure copy) to copy files between remote hosts.
  ///
  /// [from] the from path
  /// [fromHost] the host the [from] path exists on. If [fromHost] isn't
  /// specified it is assumed that the from path is on the local machine
  /// [fromUser] the user to use to authenticate against the [fromHost].
  ///   You may only specify [fromUser] if [fromHost] is passed.
  ///
  /// [to] the path on the [toHost] to copy the files to.
  /// [toHost] the host the [to] path exists on. If [toHost] isn't
  /// specified it is assumed that the from path is on the local machine
  /// [toUser] the user to use to authenticate against the [toHost].
  ///   You may only specify [toUser] if [toHost] is passed.
  /// Set [recursive] to true to do a recursive copy from the
  /// [from] path. [recursive] defaults to false.
  /// EXPERIMENTAL
  static void scp(
      {@required List<String> from,
      @required String to,
      String fromHost,
      String toHost,
      String fromUser,
      String toUser,
      bool recursive = false,
      Progress progress}) {
    if (from == null) {
      throw ScpException('You must pass a [from] path');
    }

    if (to == null) {
      throw ScpException('You must pass a [to] path');
    }
    // toUser is only valid if toHost is given
    if (toUser != null && toHost == null) {
      throw ScpException('[toUser] is only valid if toHost is also past');
    }

    // fomrUser is only valid if fromHost is given
    if (fromUser != null && fromHost == null) {
      throw ScpException('[fromUser] is only valid if toHost is also past');
    }

    var cmdArgs = <String>[];

    if (recursive) {
      cmdArgs.add('-r');
    }

    // build fromArg user@host:/path
    var fromArg = '';
    if (fromHost != null) {
      if (fromUser != null) {
        fromArg += '$fromUser@';
      }
      fromArg += '$fromHost:${from.join(" ")}';
    } else {
      fromArg = from.join(' ');
    }

    cmdArgs.add(fromArg);

    // build toArg user@host:/path
    var toArg = '';
    if (toHost != null) {
      if (toUser != null) {
        toArg += '$toUser@';
      }
      toArg += '$toHost:$to';
    } else {
      toArg = to;
    }

    cmdArgs.add(toArg);

    progress ??= Progress.devNull();

    try {
      startFromArgs('scp', cmdArgs, progress: progress, terminal: true);
    } on RunException catch (e) {
      var error = scpErrors[e.exitCode];
      throw RunException(
          e.cmdLine, e.exitCode, red('scp exit code: ${e.exitCode} - $error'),
          stackTrace: e.stackTrace);
    }
  }

  static const Map<int, String> sshErrors = <int, String>{
    0: 'Operation was successful',
    1: 'Generic error, usually because invalid command line options or malformed configuration',
    2: 'Connection failed',
    65: 'Host not allowed to connect',
    66: 'General error in ssh protocol',
    67: 'Key exchange failed',
    68: 'Reserved',
    69: 'MAC error',
    70: 'Compression error',
    71: 'Service not available',
    72: 'Protocol version not supported',
    73: 'Host key not verifiable',
    74: 'Connection failed',
    75: 'Disconnected by application',
    76: 'Too many connections',
    77: 'Authentication cancelled by user',
    78: 'No more authentication methods available',
    79: 'Invalid user name'
  };

  static const Map<int, String> scpErrors = <int, String>{
    0: 'Operation was successful',
    1: 'General error in file copy',
    2: 'Destination is not directory, but it should be',
    3: 'Maximum symlink level exceeded',
    4: 'Connecting to host failed.',
    5: 'Connection broken',
    6: 'File does not exist',
    7: 'No permission to access file.',
    8: 'General error in sftp protocol',
    9: 'File transfer protocol mismatch',
    10: 'No file matches a given criteria',
    65: 'Host not allowed to connect',
    66: 'General error in ssh protocol',
    67: 'Key exchange failed',
    68: 'Reserved',
    69: 'MAC error',
    70: 'Compression error',
    71: 'Service not available',
    72: 'Protocol version not supported',
    73: 'Host key not verifiable',
    74: 'Connection failed',
    75: 'Disconnected by application',
    76: 'Too many connections',
    77: 'Authentication cancelled by user',
    78: 'No more authentication methods available',
    79: 'Invalid user name'
  };
}

class ScpException extends RemoteException {
  ScpException(String message) : super(message);
}

class RemoteException extends DShellException {
  RemoteException(String message) : super(message);
}