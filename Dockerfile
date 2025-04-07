# Use the official Python image as the base image
FROM python:3.10-slim AS base


# sudo apt install -y gcc g++ gfortran libopenblas-dev liblapack-dev pkg-config
RUN apt-get update && apt-get install -y gosu emacs git gcc g++ make libhdf5-dev libnetcdf-dev libomp-dev libopenmpi-dev openmpi-bin
# Set the working directory in the container
WORKDIR /starships

# Install the dependencies
# scipy 1.11.2 is required for 'scipy.signal.gaussian'
# matplotlib 3.7.2 is required for 'matplotlib.tri.triangulation'
COPY ./requirements.txt /starships/requirements.txt
RUN export HDF5_DIR=/usr/include/hdf5 && \
# petitRADTRANS requires numpy to be installed prior to pip install...
    pip install numpy==1.26 --no-cache-dir && \
    pip install -r /starships/requirements.txt --no-cache-dir



# Note: exofile is required to run the starships code.
# v0.2.2 from pypy is bugged and records the version number as 0.0.0 which throws an error
# when trying to install starships
# Installing from the git repository fixes this issue.
RUN git clone --depth 1 --branch v0.2.2 https://github.com/AntoineDarveau/exofile.git && \
    cd exofile &&  pip install . --no-cache-dir

# Note: 'python setup.py install' is required to correctly install batman-package v2.4.8. 
# "pip install ." will work with newer versions (2.5) of batman-package. 
RUN git clone -b developolivia --single-branch https://github.com/orpereira/starships.git && \
    cd starships && \
    # Change the numpy version in the setup.py file to 1.26
    sed -i 's/numpy>=1.23.0/numpy>=1.24/g' setup.py && \
    python setup.py install 


# Create a second stage
# Having multiple stages helps us reduce the size of the image
FROM python:3.10-slim AS runtime

# Copy across installed packages from the first stage
# We only copy across what we need, the rest is discarded in the previous stage
COPY --from=base /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=base /usr/local/bin /usr/local/bin
COPY --from=base /usr/local/lib /usr/local/lib
COPY --from=base /usr/local/include /usr/local/include
COPY --from=base /usr/local/share /usr/local/share
COPY --from=base /usr/sbin/ /usr/sbin/

# Create a test file
COPY ./test.py /starships/test.py


# Create a user jovyan, with a home directory and switch to that user
# RUN useradd -d /home/jovyan -m jovyan
# USER jovyan
# WORKDIR /home/jovyan/
# RUN mkdir -p /home/jovyan/starships_data && mkdir -p /home/jovyan/.local
# ENV pRT_input_data_path=/home/jovyan/starships_data

# Create entrypoint to change ownership of the jupyter directory
# RUN chown -R jovyan /home/jovyan/.local && chown -R jovyan /home/jovyan/starships_data

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

ENV pRT_input_data_path=/home/jovyan/starships_data

EXPOSE 8888
WORKDIR /home/jovyan/
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
