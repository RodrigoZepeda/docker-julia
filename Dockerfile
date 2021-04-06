FROM ubuntu:focal
ARG JULIA_VERSION="1.6.0"

#Change shell from sh to bash
SHELL ["/bin/bash", "-c"]

#Install wget
RUN apt-get update && apt-get upgrade -y && apt-get install -y wget

#Install Julia
RUN echo "Installing Julia version $JULIA_VERSION" && \
    JULIA_MAJOR=`echo $JULIA_VERSION | sed -E  "s/\.[0-9]+$//g"` && \
    echo "Major version of julia is $JULIA_MAJOR" && \
    wget https://julialang-s3.julialang.org/bin/linux/x64/$JULIA_MAJOR/julia-$JULIA_VERSION-linux-x86_64.tar.gz && \
    tar -xvzf julia-$JULIA_VERSION-linux-x86_64.tar.gz && \
    cp -r julia-$JULIA_VERSION /opt/ && \
    ln -s /opt/julia-$JULIA_VERSION/bin/julia /usr/local/bin/julia && \
    rm -r julia-$JULIA_VERSION-linux-x86_64.tar.gz

#Install code-server
RUN wget https://github.com/cdr/code-server/releases/download/v3.9.0/code-server-3.9.0-linux-amd64.tar.gz && \
    tar -xvf code-server-3.9.0-linux-amd64.tar.gz && \
    chmod +x code-server-3.9.0-linux-amd64 && \
    rm code-server-3.9.0-linux-amd64.tar.gz

#Install code-server extensions from vsix (Julia)
RUN wget https://github.com/julia-vscode/julia-vscode/releases/download/v1.1.30/language-julia-insider-1.1.30.vsix && \
    code-server-3.9.0-linux-amd64/bin/code-server --install-extension language-julia-insider-1.1.30.vsix 

#Expose path
EXPOSE 3838

#Expose path
ENV JULIA_PATH=/usr/local/bin/julia
ENV JULIA_NUM_THREADS=1

#Add the Project.toml file
ADD julia_config/Project.toml /root/
ADD julia_config/startup.jl /root/.julia/config/startup.jl
ADD julia_config/config_project.jl /root/

#Install code-server extensions from vsix (TOML)
RUN wget https://open-vsx.org/api/bungcip/better-toml/0.3.2/file/bungcip.better-toml-0.3.2.vsix && \
    code-server-3.9.0-linux-amd64/bin/code-server --install-extension bungcip.better-toml-0.3.2.vsix

WORKDIR /root/
RUN julia config_project.jl
RUN rm config_project.jl

#Run server
CMD /code-server-3.9.0-linux-amd64/bin/code-server \
    --bind-addr 0.0.0.0:3838 \
    --disable-telemetry \
    --auth "none"