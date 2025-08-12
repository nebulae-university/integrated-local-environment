# INTEGRATED LOCAL ENVIRONMENT (ILE)
FullStack multi-µService local environment

# Local Machine Requirements

Only available for Linux and MacOS (Darwin).  
Needed Software packages:
- NVM (node version manager) with node 10, 12 and 14 pre-installed
- NVM path exported at ~/.bashrc or  ~/.zprofile files

Directory structure:  
All shells, µServices and this project must be in the same directory.  
Running the ls command on the base directory should output the following result:
```sh
% ls NEBULAE_UNIVERSITY
emi
emi-gateway
external-network-gateway
external-system-gateway
integrated-local-environment
ms-acss
ms-device-mng
ms-enduser-mng
ms-event-store-mng
ms-general-monitor
ms-organization-mng
ms-payment-medium-mng
ms-route-mng
ms-sales-mng
ms-service-mng
ms-shift-clearing
pis
````

# Pre-Build FrontEnd and API Shells

Shells need to be compose and pre-build before running the environment
## FrontEnd Shells
Merge all µFrontEnd from all µServices (ms-*) and compile it to generate a distribution
```sh
# FrontEnd EMI
bash emi/pre_build.sh

# FrontEnd PIS
bash pis/pre_build.sh
```

## API Shells
Merge all µAPIs from all µServices (ms-*) and generate a distribution
```sh
# API emi-gateway
bash emi-gateway/pre_build.sh

# API pis-gateway
bash pis-gateway/pre_build.sh

# API external-system-gateway
bash external-system-gateway/pre_build.sh

# API external-network-gateway
bash external-network-gateway/pre_build.sh
```


# Build docker compose environment
Create docker images for each shell and backend.  Remember to re-build each time you the code changes in any backend or if any of the shells are re-composed
```bash
COMPOSE_PROFILES=all docker compose build
````

# Keycloak configuration

### Start Keycloak
```bash
COMPOSE_PROFILES=keycloak docker compose up
```

Login at http://localhost:8080/admin  
- User: admin
- Password: admin

### Import NEBULAE_UNIVERSITY Realm
Import realm with the file at [infraestructure/keycloak-realm-export.json](infraestructure/keycloak-realm-export.json)

### Setup Platform Admin User
Create a PLATFORM-ADMIN user in order to LogIn into the system for an initail setup  

![Alt text](docs/assets/keycloak_paltform_admin.png?raw=true "keycloak PLATFORM-ADMIN")


### Setup Backend User
Create the keycloak_backend user:
- user: keycloak_backend
- password: keycloak_backend
With the following client roles:  

![Alt text](docs/assets/keycloak_backend_user.png?raw=true "keycloak_backend")

### Setup JWT Public Key
Navigate to [http://localhost:8080/admin/master/console/#/NEBULAE_UNIVERSITY/realm-settings/keys](http://localhost:8080/admin/master/console/#/NEBULAE_UNIVERSITY/realm-settings/keys) copy the Public Key  
![Alt text](docs/assets/keycloak_real_public_key.png?raw=true "keycloak Public Key")

Configure the JWT_PUBLIC_KEY key at [backends/backend.env](backends/backend.env) 

# Run the environment
```bash
# Start all infrastructure services 
COMPOSE_PROFILES=infrastructure docker compose up -d

# Start basic infrastructure services 
COMPOSE_PROFILES=basic docker compose up -d

# Everything else
COMPOSE_PROFILES=all docker compose up -d

# EMI CRUD Only
COMPOSE_PROFILES=crud docker compose up -d
```
