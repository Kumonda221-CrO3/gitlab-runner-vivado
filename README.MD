# gitlab-runner-vivado  
> Vivado in GitLab-Runner  
> 让你能够通过 GitLab CI/CD 流程生成 bitstream （或更多你想用vivado做的事情）   

&emsp;&emsp;把你的 Vivado 扔到 Docker 里，或者 WSL2 虚拟机里似乎没什么意义。但如果你想把 Vivado 部署到你的服务器上（或者学校服务器，或者自己的工作站，或者你的NAS？），并且利用 GitLab 来完成一些自动化编译过程，那么使用 Docker 可以**很大程度上简化你的部署和管理过程**。如果你有能力又有想法，那么你还可以利用类似的平台做更加有意义的事情（比如）。  
&emsp;&emsp;灵感来自于：
- **龙芯中科 在线实验平台** NSCSCC "龙芯杯"
- **z4yx/vivado-docker** https://github.com/z4yx/vivado-docker

## **0. 开始之前**

&emsp;&emsp;本文假设你已经部署好了 Docker 与 GitLab。如果你不知道怎么部署，请参考以下的链接：  

- https://www.docker.com/  
- https://gitlab.cn/install/  

&emsp;&emsp;在你开始接下来的步骤之前，你或许可以先简单阅读一下Dockerfile。

## **1. 部署你的 GitLab-Runner**  
&emsp;*注 1：你当然也可以不使用 Docker 来部署你的 GitLab-Runner 和 Vivado。你可以参考 GitLab-Runner 的相关在线资料，以及本文的流程，来完成在 Docker 之外的部署。*  
&emsp;*注 2：如果你不需要使用GitLab-Runner，或者不需要在WSL2等虚拟机内部署 Vivado，本文可能对你没有什么帮助。*  

### **1.1 构建你的Docker映像**   
#### **1.1.1 确保你的所有文件都准备好了**
&emsp;&emsp;**[step 1]** 你需要登录 AMD Xilinx 的官网下载你所需要的 Vivado 版本的安装文件（后文将以 Vivado 2019.2 为例），然后把它拷贝到你的工作目录之下。  
&emsp;&emsp;**注意：** 一般来说，你需要下载格式为 ``tar/gzip`` 的全平台完整安装文件。  

&emsp;&emsp;**[step 2]** 你需要将 ``Dockerfile`` 和 ``install_config.txt`` 文件复制到你的工作目录之下。  

#### **1.1.2 看看你要安装什么？**
&emsp;&emsp;**[step 1]** 打开目录下的 ``install_config.txt``。  

&emsp;&emsp;**[step 2]** 查看 ``Edition`` 项。  
```
#### Vivado HL WebPACK Install Configuration ####
Edition=Vivado HL WebPACK
```
&emsp;**注意：** 附带的 ``install_config.txt`` 是针对 Vivado 2018 与 Vivado 2019 的。对于更高版本的 Vivado 甚至是 Vitis，``Edition`` 项可能需要另外修改，在此处不作额外说明。  

&emsp;&emsp;**[step 3]** 查看 ``Modules`` 项，选择你需要的模块。  
```
# Choose the Products/Devices the you would like to install.
Modules=Virtex UltraScale+ HBM:1,Zynq UltraScale+ MPSoC:1,DocNav:0,Kintex UltraScale:1,Artix-7:1,Zynq-7000:1,System Generator for DSP:0,Virtex UltraScale+:1,Kintex UltraScale+:1,Model Composer:0
```
&emsp;&emsp;你可能不需要其中一些器件，你可以将对应的项目改为 ``0``。  
&emsp;&emsp;一般来说，你要在 Docker 中安装 Vivado，是不会使用到 DocNav、System Generator、Model Composer 这些工具的，所以这些项目在文件中默认是 ``0`` 的。    

#### **1.1.3 Press the button!!!**
&emsp;&emsp;**[step 1]** 打开你的控制台，确保在你的工作路径之下，键入以下指令：    
```
docker build --build-arg VIVADO_VERSION=2019.2 \
    --build-arg VIVADO_INSTALL_TAR=Xilinx_Vivado_2019.2_1106_2127.tar.gz \
    --build-arg VIVADO_INSTALL_CFG=intall_config.txt \
    --tag rismd/gitlab-runner-vivado:2019.2 .
```
&emsp;**注意：** 如果你正在使用 PowerShell，那么注意以上的换行符则不应该是 ``\``，或者从 ``Dockerfile`` 中复制在一整行内的指令。**指令的最后有一个 `.`,别漏了！**  
&emsp;&emsp;**[step 2]** ``docker build`` 过程会需要一些时间。请坐和放宽，*或者在地平线墨西哥里转上两圈。*

### **1.2 运行你的 GitLab-Runner 实例**  
&emsp;&emsp;在控制台内键入以下指令：
```
docker run --security-opt seccomp=unconfined \
    --name gitlab-runner-vivado-2019.2 \
    -itd \
    rismd/gitlab-runner-vivado:2019.2
```
&emsp;**注意**：``--security-opt seccomp=unconfined`` 项不总是必须的，但是在基于 Windows 的 Docker Desktop 中如果不使用这一项，Vivado 有可能会在编译过程中出错。  
&emsp;&emsp;其中 ``--name gitlab-runner-vivado-2019.2`` 指定的是实例的名称，你可以根据自己喜好或需求修改。  

## **2. 将 Vivado 连接至 GitLab**
### **2.1 注册 Runner**
&emsp;&emsp;在 ``Dockerfile`` 中并不涉及 GitLab-Runner 的注册过程，所以在实例启动之后，你需要手动注册你的 runner 服务。  
&emsp;&emsp;**[step 1]** 在控制台内键入以下指令，进入实例中的 bash：  
```
docker exec -it gitlab-runner-vivado-2019.2 bash
```
&emsp;**注意：** 如果你正在使用 PowerShell，那么注意以上的换行符则不应该是 ``\``，或者从 ``Dockerfile`` 中复制在一整行内的指令。指令中的 ``gitlab-runner-vivado-2019.2 `` 应当替换成实际的实例名称（如果你修改过）。  
&emsp;&emsp;**[step 2]** 在实例内键入以下指令，并跟随流程完成注册：
```
gitlab-runner register
```
&emsp;**注意：** 注册指令的具体参数由你的 GitLab，以及你的网络配置确定。在 GitLab 的 Admin Area 中可以生成带参数的注册指令，具体流程请参阅互联网。  

### **2.2 运行 Runner （应用 CI 流程）**
&emsp;*注：本节内容仅最为一种建议，如果你熟悉 GitLab CI/CD 的配置与运行，你可以跳过这一章，并采用不同的方法。*  
&emsp;&emsp;在你使用 ``gitlab-runner register`` 指令注册你的 runner 时，会提示你输入 ``tag`` 名称：  
```
Enter tags for the runner (comma-separated):
vivado-2019.2
```
&emsp;&emsp;你可以如上输入 ``vivado-2019.2``，给予你的 runner 相应的 ``tag``，这样会比较方便管理。  
&emsp;&emsp;在配置 ``.gitlab-ci.yml`` 时，在相应的位置写入 ``tag`` 名称即可指定 runner。这样在 GitLab 中启动 CI/CD Pipeline 时，安装有 Vivado 的 GitLab-Runner 就会被自动选中来执行集成编译过程。  
&emsp;&emsp;对于 ``.gitlab-ci.yml`` 配置文件，可以参考下例：  
```yml
stages:
  - build

bitstream:
  stage: build
  tags:
    - vivado-2019.2
  script:
    - vivado -mode tcl -source bitstream.tcl thinpad_top.xpr
    - test -f thinpad_top.runs/impl_1/*.bit

  artifacts:
    paths:
      - thinpad_top.runs/impl_1/*.bit
      - thinpad_top.runs/*/runme.log
```  
&emsp;&emsp;
&emsp;&emsp;你也可以参考我的工程：[![pipeline status](http://git.rismd.cn/Kumonda221/RMM4NC30F2X.EmbedFire/badges/master/pipeline.svg)](http://git.rismd.cn/Kumonda221/RMM4NC30F2X.EmbedFire/)  
