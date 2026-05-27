FROM node:14-bullseye

RUN apt-get update && apt-get install -y \
    git \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/genieacs/genieacs-sim.git /opt/genieacs-sim

WORKDIR /opt/genieacs-sim

RUN npm install

RUN chmod +x ./genieacs-sim

CMD ["bash", "-lc", "until test -f /data/data_model_easymesh.csv; do echo 'Esperando modelo EasyMesh generado por el adaptador...'; sleep 5; done; until curl -s -o /dev/null -w '%{http_code}' http://genieacs:7547/ | grep -q '405'; do echo 'Esperando a GenieACS CWMP en genieacs:7547...'; sleep 5; done; echo 'GenieACS CWMP disponible. Arrancando CPE virtual EasyMesh...'; ./genieacs-sim --acs-url http://genieacs:7547/ --data-model /data/data_model_easymesh.csv --processes 1 --serial 200001"]
