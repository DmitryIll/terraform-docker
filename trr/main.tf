variable hostname_blocks {}
variable name_bloks {}
variable images_blocks {}
variable cores_blocks {}
variable memory_blocks {}
variable core_fraction_blocks {}

variable count_vm {}

#---- vms --------------
resource "yandex_compute_instance" "vm" {

  count = "${var.count_vm}"

  name = "${var.name_bloks[count.index]}" 
  hostname = "${var.hostname_blocks[count.index]}" 

  allow_stopping_for_update = true
  platform_id               = "standard-v1" 
  #zone                      = local.zone

  resources {
    core_fraction = "${var.core_fraction_blocks[count.index]}" 
    cores  = "${var.cores_blocks[count.index]}" 
    memory = "${var.memory_blocks[count.index]}"  
  }

  boot_disk {
    initialize_params {
      image_id = "${var.images_blocks[count.index]}"
      size = 16
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}" 
    nat       = true
  }

  scheduling_policy {
  preemptible = true
   }

 metadata = {
    user-data = "${file("./meta.yaml")}" 
  }

#---------- создаем папки -----

  provisioner "remote-exec" {
    inline = [
     "cd ~",
     "mkdir -pv configs",
     "mkdir -pv docker_volumes",
     ]
  }

#---------- копируем файлы ----

  provisioner "file" {
    source      = "../docker-compose.yaml"
    destination = "/root/docker-compose.yaml"
  }


#----------------------------------------------------------

  provisioner "remote-exec" {
    inline = [
    "sudo apt-get update",
    "sudo apt-get install -y ca-certificates curl gnupg",
    "sudo install -m 0755 -d /etc/apt/keyrings",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
    "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
    "echo \"deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \"$(. /etc/os-release && echo \"$VERSION_CODENAME\")\" stable\" |  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
    "sudo apt-get update",
    "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
    "sudo chmod +x /root/docker-compose.yaml",
    ]
  }

#    "sudo docker compose up -d"


    connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file("id_ed25519")}"
      host = self.network_interface[0].nat_ip_address
    }
 
}


