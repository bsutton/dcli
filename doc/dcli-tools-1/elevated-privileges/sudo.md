# Sudo

You will often want to run a DCli script using sudo.

Using sudo can complicate things:

There are two core issues:

1\) on debian \(and probably other distros\) sudo has its own path which is unlikely to include the dart or dcli paths.

2\) when trying to run a dart script you may cause the pub cache to be update at which point it will be owned by root and your normally user account won't be able to access it.

If you do this by mistake you can run the following command to fix the problem.

```bash
sudo chmod -r $USER:$USER ${HOME}/.pub-cache
```

3\) You only want parts of your script to run as privileged.

{% hint style="info" %}
The following dart code also works on Windows. The privilege options simply check that you are running as an Administrator and throw an exception if you are not. Running as a Windows Administrator does not have the same problems that sudo introduces.
{% endhint %}

## Solutions

The following provides guidelines on how to solve the problems.

1\) where ever possible avoid using sudo. Of course this often just isn't practical

2\) use the 'start' function and pass in the privileged flag:

```text
'chmod +x script.dart'.start(privileged: true);
```

The privileged flag will check if you are running as sudo,  if not it will run the chmod script under sudo. This will cause sudo to prompt the user for their sudo password.

This is a good technique as it limits the use of sudo to just those parts of the script that actually need sudo.

3\) compile the script.

Compiling your dart script has a number of benefits.

A compiled script is a completely self contained executable which means it will never cause your pub cache to be accessed which means sudo won't screw it up.  

It also fixes the path issues as you don't need dart or dcli on your path for the script to run.

```text
dcli compile script.dart
sudo ./script
```

3\) pass your path down to sudo

```text
sudo env "PATH=$PATH" <my dcli script>
```

This technique passes your existing user path into sudo which means it can find both dart and dcli.

This method is still dangerous as if dart decides your script needs to be updated then your pub cache will become owned by root.

4\) Use withPrivileges

The intent is to allow you to start your script with sudo but only the parts of your script to that need sudo will actually use it.

We still recommend you compile your script to avoid dart changing permissions on pub-cache.

You do this by starting your script with sudo but immediately downgrading your sudo access when the script starts and then using the withPrivileges method for those parts of your script that need to run as sudo.

```text
// get_keys.dart
void main()
{
    /// downgrade script to not run as sudo
    Shell.current.releasePrivilege();
    
    ... do some non-sudo things
    
    /// any code within the following code block will be run
    /// with sudo privileges.
    Shell.current.withPrivileges(() {
        copyTree('\etc\keys', '\some\insecure\location');
    });
}
```

To run the above script:

```text
dcli compile get_keys.dart
sudo ./get_keys
```

