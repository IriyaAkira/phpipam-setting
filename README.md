# phpipam-setting
## Getting Start
Execute the following in your home directory or similar location:  
```bash
git clone https://github.com/IriyaAkira/phpipam-setting.git phpipam
```

Edit /root/.smbcredentials
```yaml
username=smbuser
password=secretpassword
domain=WORKGROUP
```

Execute sudo ./scripts/start.sh

## Lisence
This repository does not contain any application code or Docker images.

It only provides scripts to pull and run the official phpIPAM Docker image:
- https://hub.docker.com/r/phpipam/phpipam-www

Please refer to the original project and Docker image page for license information.