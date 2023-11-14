#!/usr/bin/env python3

# requires: scipy, numpy, pandas, astropandas
# usage example (--help):
#   ./kids_assign_lensfit_weights.py \
#       -t /net/home/fohlen13/jlvdb/KiDS/legacyCCs/data/KiDS_DR5_superuser.pqt \
#       -i /path/to/OMEGACAM_151p1_2p0_r_SDSS.V1.2.0A_ugriZYJHKs_photoz.cat \
#       -o OMEGACAM_151p1_2p0_r_SDSS.V1.2.0A_ugriZYJHKs_photoz_lfweight.fits \
#       --psf PSF_RAD_float

from __future__ import annotations

import argparse
from typing import TYPE_CHECKING

import astropandas as apd
from scipy.spatial import KDTree

if TYPE_CHECKING:
    from numpy.typing import NDArray
    from pandas import DataFrame, Series


default_features = ["MAG_AUTO", "FLUX_RADIUS", "ABgaper", "Z_B", "PSF_RAD"]


parser = argparse.ArgumentParser(
    description="Assign label from training catalogue to target catalogue using nearest-neighbour match in feature space."
)
parser.add_argument(
    "-i", "--input", required=True,
    help="path to the target file",
)
parser.add_argument(
    "-o", "--output", required=True,
    help="path to the output with added label",
)
parser.add_argument(
    "-t", "--train", required=True,
    help="path to the training data containing the desired label",
)
parser.add_argument(
    "--psf", required=True, type=float,
    help="PSF size measurement (PSF_RAD)",
)
parser.add_argument(
    "--features", nargs="+", default=default_features,
    help="column names of features to match, must be present in input and training data",
)
parser.add_argument(
    "--label", required=True,
    help="column name of the label to match",
)
parser.add_argument(
    "--sparse", default=1, type=int,
    help="sparse-sample the training data by taking every n-th data point"
)


def whiten(
    features_df: DataFrame,
    whiten_df: DataFrame | None = None,
) -> NDArray:
    # subtract median and and rescale by inverse nMAD
    if whiten_df is None:
        whiten_df = features_df
    median = whiten_df.median()
    nmad = 1.4826 * (whiten_df - median).abs().median()
    return ((features_df - median) / nmad).to_numpy()


def match_weights(
    weights: Series,
    train_data: DataFrame,
    test_data: DataFrame,
) -> NDArray:
    tree = KDTree(whiten(train_data))
    _, idx = tree.query(whiten(test_data, train_data), k=1, workers=-1)
    return weights.to_numpy()[idx]


if __name__ == "__main__":
    args = parser.parse_args()

    print("reading input data")
    train_data = apd.read_auto(args.train, columns=[*args.features, args.weight])
    train_data = train_data[::args.sparse]
    data = apd.read_auto(args.input)

    print("running matching")
    test_data = data.copy()
    if "ABgaper" not in test_data:
        test_data["ABgaper"] = test_data["Bgaper"] / test_data["Agaper"]
    if "PSF_RAD" not in test_data:
        test_data["PSF_RAD"] = args.psf

    prediction = match_weights(
        weights=train_data[args.weight],
        train_data=train_data[args.features],
        test_data=test_data[args.features],
    )

    print("writing output data")
    data[args.weight] = prediction
    apd.to_auto(data, args.output)
