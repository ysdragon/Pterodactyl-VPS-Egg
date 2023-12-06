# Pterodactyl VPS Egg

This is a Pterodactyl Egg for running a Virtual Private Server (VPS). The Egg includes several programming languages: `Python, PHP, Node.js, and Golang`. 

To use this Egg, simply add it to your Pterodactyl panel and configure it according to your needs. The included languages can be used to run a variety of applications and scripts on your VPS.

```diff
- Currently sudo su not working
```

## How to Add `sudo su` Support

To enable `sudo su` support for Pterodactyl containers, follow these steps:

1. Clone Pterodactyl's Wings from the source repository:
   ```bash
   git clone https://github.com/pterodactyl/wings
   ```

2. Comment or remove the following [line](https://github.com/pterodactyl/wings/blob/48c55af373684847c7f61035c0038c5e470e286c/environment/docker/container.go#L250) from the Wings source code:
   ```go
   SecurityOpt:    []string{"no-new-privileges"},
   ```
3. Build Pterodactyl Wings. ( go build )

4. Replace your current Wings executable, typically located at `/usr/local/bin/wings`, with the one you just built.

5. Finally, restart the Wings service:
   ```bash
   systemctl restart wings
   ```
