### Documentation for OpsMonitorTool Tool

#### Overview
The OpsMonitorTool Tool helps you  collect and display system information, including active ports, user logins, Nginx configurations, Docker images, and container statuses. This Tool consists of several scripts designed to install necessary dependencies, set up monitoring, and manage logs. This documentation covers the installation and configuration steps, usage examples for each command-line flag, and details about the logging mechanism.

### Getting Started

1. **Install Dependencies**

   The `install-deps.sh` script installs all the necessary dependencies for the tool.

   **Steps:**
   - Make the script executable:

     ```sh
     chmod +x install-deps.sh
     ```

   - Run the script to install dependencies and set up the `devopsfetch` script:

     ```sh
     sudo ./install-deps.sh
     ```
    The script is now available for usage by running `devopsfetch`. To view script usage options run: 

     ```sh
     sudo devopsfetch -h
     ```
2. **Setup Monitoring**

   Optionally you can setup the script to run in the background and edit the options at the top of the setup-monitor script to customize  monitoring options. The `setup-monitor.sh` script sets up the monitoring service using systemd. Here activities are only logged when they change, so successive duplicate activities are not logged.

   **Steps:**
   - Make the script executable:

     ```sh
     chmod +x setup-monitor.sh
     ```

   - Run the script to set up the monitoring service:

     ```sh
     sudo ./setup-monitor.sh
     ```

### Usage Examples for Command-Line Flags

The `devopsfetch` script supports multiple command-line flags:

- `-h, --help`: Display help information.
- `-t, --time <start_date> [end_date]`: Specify a start and optionally an end date.
- `-p, --port <port_number>`: Specify a port number.
- `-d, --docker <container>`: Specify Docker-related options.
- `-n, --nginx <domain>`: Specify Nginx-related options.
- `-u, --users <username>`: Specify user-related options.

**Examples:**

1. Display help information:

   ```sh
   sudo devopsfetch -h
   ```

2. Fetch activities performed within a certain time interval:

   ```sh
   sudo devopsfetch -t 2024-07-01 2024-07-07
   ```

3. Fetch all listening ports:

     ```sh
   sudo devopsfetch -p 
   sudo devopsfetch --port
   ``` 
   Retrieve details relating to a specific port:

   ```sh
   sudo devopsfetch -p 8080
   sudo devopsfetch --port 8080
   ```

4. Get information about all running Docker containers and their images:

  ```sh
   sudo devopsfetch -d
   sudo devopsfetch --docker
   ```
   Retrieve detailed information abouut to a container:

   ```sh
   sudo devopsfetch -d nginx
   sudo devopsfetch --docker nginx
   ```

5. Retrieve all NGINX domains and the ports they proxy to:

   ```sh
   sudo devopsfetch -n 
   sudo devopsfetch --nginx 
   ```
   Retrive detailed information about a specific NGINX domain configuration:

   ```sh
   sudo devopsfetch -n domain.com
   sudo devopsfetch --nginx domain.com
   ```

6. Retrieve information about users and their login times:

   ```sh
   sudo devopsfetch -u
   sudo devopsfetch --users
   ```
   Retrieve detailed information about a specific user
   ```sh
   sudo devopsfetch -u olatunji
   sudo devopsfetch --users olatunji
   ```

### Logging Mechanism

Logs are stored in `/var/log/devopsfetch` with subdirectories based on the activities being monitored.For example, Ports logs and logs for port 80 would be stored in  `/var/log/devopsfetch/ports.log` or `/var/log/devopsfetch/port-80.log` respectively.  Logs are rotated daily and are named according to the date which they were collected.


**Retrieving Logs:**

To retrieve logs, navigate to the log directory and list the folders:

```sh
ls /var/log/devopsfetch
```

To view a specific log file:

```sh
cat /var/log/devopsfetch/<log_type>.log
```

---

**Log Rotation:**

Log files are rotated daily using logrotate, and you can view up to 7  ensuring that logs are maintained without consuming excessive disk space. This rotation helps in managing log files efficiently and keeps the system running smoothly.

---

This documentation provides a comprehensive guide to installing, configuring, and using the DevOps Fetch Tool, along with managing and retrieving logs effectively.

