#!/bin/sh

clear
  echo "\e[32m╭────────────────────────────────────────────────────────────────────────────────╮\e[0m"
  echo "\e[32m│                                                                                │\e[0m"
  echo "\e[32m│                             Pterodactyl VPS EGG                                │\e[0m"
  echo "\e[32m│                                                                                │\e[0m"
  echo "\e[32m│                           © 2021 - 2024 ysdragon                               │\e[0m"
  echo "\e[32m│                                                                                │\e[0m"
  echo "\e[32m╰────────────────────────────────────────────────────────────────────────────────╯\e[0m"
  echo "                                                                                                "
  echo "root@MyVPS:~                                                                                    "

run_cmd() {
    read -p "root@MyVPS:~ " CMD
    eval "$CMD"
    echo "root@MyVPS:~ "
    run_user_cmd
}

run_user_cmd() {
    read -p "user@MyVPS:~ " CMD2
    eval "$CMD2"
    echo "root@MyVPS:~ "
    run_cmd
}

run_cmd
