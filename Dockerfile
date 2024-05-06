FROM alpine:latest as builder

# Atualizando pacotes e instalando dependências
RUN apk update && \
    apk add --no-cache wget unzip curl

# Instalando o Terraform
RUN wget https://releases.hashicorp.com/terraform/1.8.2/terraform_1.8.2_linux_amd64.zip && \
    unzip terraform_1.8.2_linux_amd64.zip && \
    mv terraform /usr/local/bin/

# Instalando o AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin

WORKDIR /work/

# Criando diretório para as credenciais da AWS

# STAGE 2
FROM alpine:latest

WORKDIR /work

COPY app/ .

RUN mkdir aws

COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=builder /usr/local/aws-cli /usr/local/aws-cli
COPY --from=builder /work /work

ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION

# Configurando as credenciais da AWSS
RUN echo "[default]" >> aws/credentials && \
    echo "aws_access_key_id = ${AWS_ACCESS_KEY_ID}" >> aws/credentials && \
    echo "aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}" >> aws/credentials

# Instalando Python e dependências
RUN apk add --no-cache python3 python3-dev py3-pip
    
RUN pip3 install -r /work/requirements.txt

EXPOSE 8080

# Rodando a aplicação
CMD ["python3", "app.py"]
