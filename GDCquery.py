#!/usr/bin/env python

#Replace < > with appropriate paths/file names
import requests
import json
import pandas as pd

token_file = "<path to GDC token file>"

normal_files = pd.read_excel("<path to TCGA data file with file IDs>")
file_ids = normal_files["File ID"]


with open(token_file,"r") as token:
    token_string = str(token.read().strip())
    
for f_id in file_ids:
    data_endpt = "https://api.gdc.cancer.gov/slicing/view/{}".format(f_id)
    params = {"gencode": ["PPP2R1B"]}

    response = requests.post(data_endpt,
                            data = json.dumps(params),
                            headers = {
                                "Content-Type": "application/json",
                                "X-Auth-Token": token_string
                                })

    file_name = "<path to BAM files folder>/ppp2r1b_{}.bam".format(f_id)

    with open(file_name, "wb") as output_file:
        output_file.write(response.content)




