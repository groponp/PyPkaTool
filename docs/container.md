# Container (Apptainer / Docker)

For reproducibility - HPC clusters, CI, or just sharing an exact working
environment without asking someone to run three `conda env create`
commands - the three conda environments described in
{doc}`installation` are bundled into a single container image instead.

## Apptainer / Singularity

[`apptainer.def`](https://github.com/groponp/PyPkaTool/blob/main/apptainer.def)
is the native definition. It installs all three environments
(`pypkatool`, `py27`, `pdbfixer`) under `/opt/conda/envs/` inside the
image, exactly mirroring the bare-metal setup:

```bash
apptainer build --fakeroot pypkatool.sif apptainer.def
apptainer run pypkatool.sif run my_protein.pdb --pH 7.0
apptainer run pypkatool.sif fixstructure --pdb-id 7A3S --outdir results/
```

Apptainer binds your `$HOME` into the container by default, but not
arbitrary paths - bind-mount your data directory explicitly if your input
PDBs live elsewhere:

```bash
apptainer run --bind /data:/data pypkatool.sif run /data/my_protein.pdb --pH 7.0
```

### Why `/opt/conda/envs/`, not `~/miniconda3/envs/`

{func}`pypkatool.core._inject_py27` and
{func}`pypkatool.core._find_pdbfixer_python` locate the `py27` and
`pdbfixer` environments by searching a fixed list of conda-root
candidates. On bare metal that's `~/miniconda3/envs/...` /
`~/anaconda3/envs/...`. Inside an Apptainer container this would not work
by default: Apptainer binds the *host's real* `$HOME` into the container
(unlike Docker, which starts from a clean filesystem), so
`Path.home() / "miniconda3/envs/..."` would resolve to whatever is on the
host, not to anything installed in the container image. `apptainer.def`
avoids the collision entirely by installing conda at the container-standard
`/opt/conda` instead, and both lookup functions check
`/opt/conda/envs/py27` / `/opt/conda/envs/pdbfixer` as an additional
candidate path specifically for this case.

## Docker

[`Dockerfile`](https://github.com/groponp/PyPkaTool/blob/main/Dockerfile)
builds the same three-environment image via Docker instead - useful for CI
or Docker Hub distribution - and converts directly to an Apptainer `.sif`
without rebuilding from source:

```bash
docker build -t pypkatool .
apptainer build pypkatool.sif docker-daemon://pypkatool:latest
# or, from an already-pushed image:
apptainer build pypkatool.sif docker://<user>/pypkatool:latest
```

```bash
docker run --rm -v "$PWD:/data" pypkatool run /data/my_protein.pdb --pH 7.0
```
