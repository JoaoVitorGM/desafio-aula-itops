FROM alpine:3.14 as builder

# Atualizando pacotesss
RUN apk add --no-cache mysql-clien update -y 

# Instalar Terraform
RUN apk add --no-cache mysql-clien-get install wget unzip curl -y

RUN wget https://releases.hashicorp.com/terraform/1.8.2/terraform_1.8.2_linux_amd64.zip

RUN unzip terraform_1.8.2_linux_amd64.zip

RUN mv terraform /usr/local/bin/

 # Instalar o Python
RUN apk add --no-cache mysql-clien-get install python3.9 -y 

RUN apk add --no-cache mysql-clien install python3-pip -y

# instalar awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install -i /usr/local/aws-cli -b /usr/local/bin

WORKDIR /work/
COPY app/ .

# Instalar os requisitos minimos (requirements.txt)
RUN python3 -m pip install -r requirements.txt

# CORRETO:
# ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} 
# ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
# ENV AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}

RUN mkdir aws


# STAGE 2
FROM alpine:3.14

WORKDIR /work

COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform 
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /work /work

ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION

# ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
# ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
# ENV AWS_DEFAULT_REGION="us-east-1"

RUN echo "[default]" >> aws/credentials
RUN echo "aws_access_key_id = $(echo $AWS_ACCESS_KEY_ID)" >> aws/credentials 
RUN echo "aws_secret_access_key = $(echo $AWS_SECRET_ACCESS_KEY)" >> aws/credentials

RUN apk add --no-cache mysql-clien-get update && apt-get install -y python3.9 python3-pip
RUN python3 -m pip install -r requirements.txt

EXPOSE 8080

# Rodar a aplicação
CMD ["python3", "app.py"]