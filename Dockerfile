FROM alpine:3.14 as builder

# Atualizando pacotes e instalando dependências
RUN apk update && \
    apk add --no-cache wget unzip curl python3 py3-pip

# Instalando Terraform
RUN wget https://releases.hashicorp.com/terraform/1.8.2/terraform_1.8.2_linux_amd64.zip && \
    unzip terraform_1.8.2_linux_amd64.zip && \
    mv terraform /usr/local/bin/

# Instalando o Python e o pip
RUN apk add --no-cache python3 python3-dev py3-pip

# Instalando o AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin

WORKDIR /work/
COPY app/ .

# Instalando os requisitos mínimos (requirements.txt)
RUN python3 -m pip install -r requirements.txt

# Configurando credenciais do AWS
RUN mkdir -p /root/.aws && \
    echo "[default]" >> /root/.aws/credentials && \
    echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> /root/.aws/credentials && \
    echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> /root/.aws/credentials

# Segunda etapa
FROM alpine:3.14

WORKDIR /work

COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=builder /usr/local/bin/aws /usr/local/bin/aws
COPY --from=builder /work /work

# Configurando as variáveis de ambiente
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION

ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ENV AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

# Instalando Python e dependências
RUN apk update && \
    apk add --no-cache python3 python3-dev py3-pip && \
    python3 -m pip install -r /work/requirements.txt

EXPOSE 8080

# Rodando a aplicação
CMD ["python3", "app.py"]