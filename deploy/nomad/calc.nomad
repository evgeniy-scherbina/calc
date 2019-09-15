job "calc" {
  datacenters = ["dc1"]

  type = "service"

  # Specify this job to have rolling updates, two-at-a-time, with
  # 30 second intervals.
  update {
    stagger      = "30s"
    max_parallel = 2
  }

  // -------------- Add Service ---------------
  group "add" {
    count = 1

    task "add" {
      driver = "docker"

      config {
        image = "scherbina/calc"
        args = [
          "add",
        ]

        port_map {
          http = 8080
        }
      }

      service {
        name = "add"
        port = "http"

        check {
          name = "Calc Add Service Health"
          type = "tcp"
          port = "http"
          interval = "30s"
          timeout = "2s"
        }
      }

      # Specify the maximum resources required to run the task,
      # include CPU, memory, and bandwidth.
      resources {
        cpu    = 500 # MHz
        memory = 128 # MB

        network {
          mbits = 100

          # This requests a static port on 8080 on the host. This
          # will restrict this task to running once per host, since
          # there is only one port 8080 on each host.
          port "http" {
            static = 8080
          }
        }
      }
    }
  }

  // -------------- Div Service ---------------
  group "div" {
    count = 1

    task "div" {
      driver = "docker"

      config {
        image = "scherbina/calc"
        args = [
          "div",
        ]

        port_map {
          http = 8080
        }
      }

      service {
        name = "div"
        port = "http"

        check {
          name = "Calc Div Service Health"
          type = "tcp"
          port = "http"
          interval = "30s"
          timeout = "2s"
        }
      }

      # Specify the maximum resources required to run the task,
      # include CPU, memory, and bandwidth.
      resources {
        cpu    = 500 # MHz
        memory = 128 # MB

        network {
          mbits = 100

          # This requests a static port on 8083 on the host. This
          # will restrict this task to running once per host, since
          # there is only one port 8083 on each host.
          port "http" {
            static = 8083
          }
        }
      }
    }
  }
}
