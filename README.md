# PS Doc Generator

## 1 &nbsp;&nbsp; Introduction

### 1.1 &nbsp;&nbsp; Why generate reports?

Writing engagement reports is tedious and error-prone - a lot of time is spent manually extracting information from
Cloudera Manager and the base systems, and then painstakingly formatting them in the giant MS Word document template.

Despite all the time and effort, the resulting document often has omissions and mistakes. It is also inconsistent in
terms of formatting and content, as there is only one template for ALL engagement types and different SA/SCs choose to
include different sections. Having the template in a MS Word document itself is problematic - it is hard to maintain
consistent formatting and track/merge changes.  

All this hard work and time wasted can be better spent on higher value work. So let's automate all the grunt work, which
will give us 80-90% of the final engagement report and we just have to fill in the rest.

### 1.2 &nbsp;&nbsp; How does it work?

We first run a simple Shell script (`cm-info.sh`) to collect the required information from Cloudera Manager ("CM") via
the CM API. This is deliberately kept as simple as possible (e.g. Bash instead of Python) with minimal dependencies so
that we can easily run it in customer environments.

Then we take the (JSON) output and run it against our internal document generator which generate a
[LaTeX](https://www.latex-project.org/get/) document, that in turn is compiled into PDF - with all the cluster and
system information filled out and in proper Cloudera document template. It can then be further edited to include other
non-standard/generated content and customised.

Note that this document generator tool is STRICTLY INTERNAL - do not share with customers or even delivery partners. In
fact, avoid letting externals know we have such a tool as it may devalue our report/work/pricing.

### 1.3 &nbsp;&nbsp; What is LaTeX?

LaTeX is a popular free open source typesetting language and program that we use to generate the PDF reports from the
`.tex` markup files. Content is decoupled from the formatting (similar to HTML and CSS), allowing us to produce
consistent and professional reports with minimal effort.

LaTeX itself has a steep learning curve, but all the hard work has been done here already, so one can just learn the
bare minimum needed, which is easy. One key advantage of such a markup language is that it is simple plaintext, not
binary (or complex XML like .docx/.odf). This makes it easy and natural to track changes to the templates in Git.

## 2 &nbsp;&nbsp; Running it

### 2.1 &nbsp;&nbsp; Initial first-time setup

1. Install [MacTeX](http://www.tug.org/mactex/).
2. Install Python dependencies:

        sudo easy_install pip
        sudo pip install jinja2 pyyaml ostruct

3. Install the [Roberto](https://fonts.google.com/specimen/Roboto?selection.family=Roboto) font. Just download and
   double click to install on MacOS.

### 2.2 &nbsp;&nbsp; Generate standard docs

For example, run the following commands to generate the CDSW, cluster deployment, disk guidelines, and security prereqs
documents respectively:

    ./doc-gen.py make-pdf -t src/latex/templates/cdsw-prereqs.tex
    ./doc-gen.py make-pdf -t src/latex/templates/deploy-prereqs.tex
    ./doc-gen.py make-pdf -t src/latex/templates/disk-guidelines.tex
    ./doc-gen.py make-pdf -t src/latex/templates/security-prereqs.tex

### 2.3 &nbsp;&nbsp; Generate custom engagement doc

#### 2.3.1 &nbsp;&nbsp; Collect cluster information

Use the `cm-info.sh` script to get information from Cloudera Manager. 

Sample usage (Cloudera VPN required for this example since it connects to the internal nightly builds):

    ./cm-info.sh --host http://nightly513-1.gce.cloudera.com:7180 -u admin -p admin


Sample output:

    Sun Dec 31 00:44:19 +08 2017 [INFO ] Cloudera Manager seems to be running
    Sun Dec 31 00:44:20 +08 2017 [INFO ] Getting Cloudera Manager config
    Sun Dec 31 00:44:22 +08 2017 [INFO ] Getting Cloudera Manager role configs
    Sun Dec 31 00:44:23 +08 2017 [INFO ]  - Getting role config for mgmt-ACTIVITYMONITOR-BASE
    ...
    Sun Dec 31 00:44:31 +08 2017 [INFO ]  - Getting role config for mgmt-SERVICEMONITOR-BASE
    Sun Dec 31 00:44:32 +08 2017 [INFO ] Getting redacted deployment configs
    Sun Dec 31 00:44:35 +08 2017 [INFO ] Processing Cluster 1...
    Sun Dec 31 00:44:36 +08 2017 [INFO ]  - Getting service config for ACCUMULO16-1
    Sun Dec 31 00:44:43 +08 2017 [INFO ]  - Getting service config for FLUME-1
    ...
    Sun Dec 31 00:45:52 +08 2017 [INFO ]  - Getting service config for ZOOKEEPER-1
    Sun Dec 31 00:45:56 +08 2017 [INFO ]  - Got host config for nightly513-2.gce.cloudera.com
    ...
    Sun Dec 31 00:45:57 +08 2017 [INFO ]  - Got host config for nightly513-3.gce.cloudera.com
    Sun Dec 31 00:45:58 +08 2017 [INFO ] Wrote to nightly513-1.gce.cloudera.com.20171231-0044.tar.bz2


#### 2.3.2 &nbsp;&nbsp; Generate custom report template

For example:

    ./doc-gen.py make-tex -c conf/Nightly513-Cluster-20171231.yaml

Sample output:

    2018-06-12 23:47:59 TexMaker   INFO    Rendering src/latex/templates/deploy-report/00_preamble.tex
    2018-06-12 23:47:59 TexMaker   INFO    Rendering src/latex/templates/deploy-report/01_intro.tex
    2018-06-12 23:47:59 TexMaker   INFO    Rendering src/latex/templates/deploy-report/02_infra.tex
    2018-06-12 23:47:59 TexMaker   INFO    Rendering src/latex/templates/deploy-report/03_cluster_config.tex
    2018-06-12 23:47:59 TexMaker   INFO    Rendering src/latex/templates/deploy-report/10_sys_arch.tex
    2018-06-12 23:47:59 TexMaker   INFO    Rendering src/latex/templates/deploy-report/11_cluster_config.tex
    2018-06-12 23:47:59 TexMaker   INFO    Rendering src/latex/templates/deploy-report/12_prod_readiness.tex
    2018-06-12 23:47:59 TexMaker   INFO    Wrote to src/latex/reports/Nightly513_Cluster-Test_Report-20171230.tex

You can now modify the resulting `.tex` file (e.g. `src/latex/reports/Nightly513_Cluster-Test_Report-20171230.tex`) in
your preferred editor as needed. When done, run the `make-pdf` command to generate the PDF. 

For example:

    ./doc-gen.py make-pdf -t src/latex/reports/Nightly513_Cluster-Test_Report-20171230.tex

You can also use the `watch` command to monitor the file for changes and have it automatically compile the PDF when
saved. For example:

    ./doc-gen.py watch -t src/latex/reports/Nightly513_Cluster-Test_Report-20171230.tex


#### 2.3.3 &nbsp;&nbsp; Sample output

Thumbnails of sample generated docs:

![Sample report thumbnail](samples/sample-report-thumbnail.png)

The full sample document is at [samples/cdh-prereqs.pdf](samples/cdh-prereqs.pdf).


## 3. &nbsp;&nbsp; For Developers

### 3.1 &nbsp;&nbsp; Install git-pylint-commit-hook

Install `git-pylint-commit-hook` by running the following command:

    pip install git-pylint-commit-hook

See https://github.com/sebdah/git-pylint-commit-hook for details.

### 3.2 &nbsp;&nbsp; Install ShellCheck

Install `ShellCheck` by running the following command:

    brew install shellcheck

See https://github.com/koalaman/shellcheck for details.

### 3.3 &nbsp;&nbsp; Git commit hook

Add the following to `.git/hooks/pre-commit` in your repository:

    #!/bin/sh

    # get updated files | only .sh files (+ .bashrc/.zshrc) | shellcheck
    git diff-index --cached --name-only $against | grep -e \.bashrc -e \.zshrc -e \.bash_profile -e \\.sh$ | xargs shellcheck

    # Checking Python using pylint
    git-pylint-commit-hook


## 4 &nbsp;&nbsp; Appendix

### 4.1 &nbsp;&nbsp; Sample usage for cm-info.sh

    ./cm-info.sh

    Cloudera Manager Info Collector v1.2.0

    USAGE:
      ./cm-info.sh [OPTIONS]

    MANDATORY OPTIONS:
      -h, --host url
            Cloudera Manager URL (e.g. http://cm-mycluster.com:7180)

      -u, --user username
            Cloudera Manager admin username

    OPTIONS:
      -p, --password password
            Cloudera Manager admin password. Will be prompted if unspecified.


### 4.2 &nbsp;&nbsp; Sample usage for doc-gen.py

    ./doc-gen.py -h
    usage: ./doc-gen.py <command> [<args>]

    The command used to generate PS Document are:

       make-tex     Generate LaTeX template (tex file) based on provided inputs
       make-pdf     Creates a PDF document from a Latex template
       watch        Watches LaTeX file for changes and rebuilds PDF

    commands:

        make-tex
            Generate template Latex (tex) file based on specified config file.

            usage: ./doc-gen.py make-tex -c conf/Telkomsel-Cluster_Health_Check-20171230.yaml

        make-pdf
            Creates a PDF document from a Latex template.

            usage: ./doc-gen.py make-pdf -t src/latex/templates/deploy-prereqs.tex

        watch:
            Automatically rebuild PDF if specified Latex template changes (same action as make-pdf).

            usage: ./doc-gen.py watch -t src/latex/templates/deploy-prereqs.tex


    PS Document Generator

    positional arguments:
      command     Subcommand to run

    optional arguments:
      -h, --help  show this help message and exit


### 4.3 &nbsp;&nbsp; Convert PDF to Microsoft Word format

There are several ways to convert `.pdf` to `.docx`, one of which is to use Adobe Acrobat Pro.
A sample `.docx` converted by Adobe Acrobat Pro is at [samples/cdh-prereqs.docx](samples/cdh-prereqs.docx).
