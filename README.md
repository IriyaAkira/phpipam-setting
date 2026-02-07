# phpipam-setting
## Getting Start
Execute the following in your home directory or similar location:  
```bash
git clone https://github.com/IriyaAkira/phpipam-setting.git phpipam
```

Edit ./phpipam/.env
```yaml
# Extract only the parts that need to be changed.
TZ=Asia/Tokyo
IPAM_DATABASE_PASS=my_secret_phpipam_pass
MYSQL_ROOT_PASSWORD=my_secret_mysql_root_pass
# For Backup
BK_SERVER=HOSTNAME
BK_SHARE=SHARENAME
MOUNT_POINT=/mnt/foo/bar
```

Edit /root/.smbcredentials For backup.
```yaml
username=smbuser
password=secretpassword
domain=WORKGROUP
```

By executing the command below, you can change whether to use HTTP only or HTTPS only.
```bash
cd ./phpipam/nginx/conf.d
# If you want to use HTTP.
ln -sf phpipam.conf.http phpipam.conf
# If you want to use HTTPS.
ln -sf phpipam.conf.https phpipam.conf
```
However, in the case of HTTP, you need to execute the following script or prepare a dummy certificate by other methods.
```bash
./phpipam/scripts/create_dummy_self-singed_certificate.sh

# When the above script is executed, rewrite the corresponding section of the following file for dummy use.
vi ./phpipam/nginx/conf.d/phpiapm.conf.http
    ssl_certificate     /etc/nginx/certs/dummy.crt;
    ssl_certificate_key /etc/nginx/certs/dummy.key;
```

Run the following as root.  
Executing this will complete the cron setup for daily project backups and the launch of the service.
```bash
./phpipam/scripts/start.sh
```

## Lisence
This repository does not contain any application code or Docker images.

It only provides scripts to pull and run the official phpIPAM Docker image:
- https://hub.docker.com/r/phpipam/phpipam-www

Please refer to the original project and Docker image page for license information.
