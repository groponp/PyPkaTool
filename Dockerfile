# Same three-environment recipe as apptainer.def (see that file's comments
# for why three separate conda envs are needed). This image can also be
# converted directly to an Apptainer/Singularity .sif for HPC use:
#   docker build -t pypkatool .
#   apptainer build pypkatool.sif docker-daemon://pypkatool:latest
# or, from a pushed image:
#   apptainer build pypkatool.sif docker://<user>/pypkatool:latest
FROM condaforge/miniforge3:latest

# pdbmender's addHtaut is a gawk script (`#!/usr/bin/gawk -f`), not a
# compiled binary - confirmed directly (its file header is literally the
# shebang text, and `ldd` reports "not a dynamic executable"). The base
# image's default `awk` is `mawk`, and `gawk` itself isn't installed at all,
# so addHtaut fails at exec with a misleading "shared library is likely
# missing" error. Every other pdbmender/pdb2pqr script is invoked by
# explicit `python2.7 <script>` (see core.py::_inject_py27), so its own
# shebang line is never exec'd - gawk is the only extra system package
# needed.
RUN apt-get update \
 && apt-get install -y --no-install-recommends gawk \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/pypkatool

COPY environment.yml environment-py27.yml environment-pdbfixer.yml ./
RUN mamba env create -f environment.yml \
 && mamba env create -f environment-py27.yml \
 && mamba env create -f environment-pdbfixer.yml \
 && mamba clean -afy

COPY pyproject.toml README.md ./
COPY pypkatool ./pypkatool

RUN /opt/conda/envs/pypkatool/bin/pip install --no-cache-dir .

ENV PATH=/opt/conda/envs/pypkatool/bin:$PATH

ENTRYPOINT ["pypkatool"]
CMD ["--help"]
