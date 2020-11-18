#!/usr/bin/env python2

#
# author: Jan Luca van den Busch
#

from __future__ import print_function, division
import os
import sys

import tabeval

sys.path.insert(0, os.path.dirname(__file__))
import ldac


def expand_path(path):
    """
    taken from: https://github.com/KiDS-WL/MICE2_mocks @ abandon-FITS-support
                -> MICE2_mocks/galmock/core/utils.py
    Normalises a path (e.g. from the command line) and substitutes environment
    variables and the user (e.g. ~/ or ~user/).
    Parameters:
    -----------
    path : str
        Input raw path.
    Returns:
    --------
    path : str
        Normalized absolute path with substitutions applied.
    """
    # check for tilde
    if path.startswith("~" + os.sep):
        path = os.path.expanduser(path)
    elif path.startswith("~"):  # like ~user/path/file
        home_root = os.path.dirname(os.path.expanduser("~"))
        path = os.path.join(home_root, path[1:])
    path = os.path.expandvars(path)
    path = os.path.normpath(path)
    path = os.path.abspath(path)
    return path


if __name__ == "__main__":
    import argparse
    import datetime

    parser = argparse.ArgumentParser(
        description="ldacfilter implementated with ldac.py - "
                    "filter LDAC tables using analytical expressions",
        epilog="Filter conditions support bracketing and implement the "
               "following operators: " + ", ".join(
                   "%s (%s)" % (o.symbol, o.ufunc.__name__)
                   for o in tabeval.math.operator_list))
    parser.add_argument(
        "-i", metavar="input", type=expand_path, required=True,
        help="input LDAC table file")
    parser.add_argument(
        "-o", metavar="output", type=expand_path, required=True,
        help="output LDAC table file")
    parser.add_argument(
        "-c", metavar="condition", required=True,
        help="filter condition to apply on table entries")
    parser.add_argument(
        "-t", metavar="table", default="OBJECTS",
        help="name of table on which filter condition is applied "
             "(default: %(default)s)")

    args = parser.parse_args()
    condition = tabeval.MathTerm.from_string(args.c.strip(";"))

    print("loading input file:  %s" % args.i)
    cat = ldac.LDACCat(args.i)
    print("accessing table:     %s" % args.t)
    tab = cat[args.t]

    try:
        print("applying filter:     %s" % condition.code)
    except AttributeError:
        raise SyntaxError("invalid expression '%s'" % args.c.strip(";"))
    mask = condition(tab)
    selected = sum(mask)
    if selected == 0:
        raise ValueError("filter condition has no matching entries")
    print("selecting entries:   %d of %d" % (selected, len(mask)))
    cat[args.t] = tab.filter(mask)

    # adding a history entry
    linewidth, linepad = 70, 2  # histroy lines display 70 characters and pad
                                # two additional spaces before the line break
    history_lines = [
        "%s called at %s" % (
            os.path.basename(__file__),
            datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")),
        "%s calling sequence:" % os.path.basename(__file__)]
    # fill remaining space with enough spaces (newline character not allowed)
    history_lines = [h.ljust(linewidth + linepad) for h in history_lines]
    # assemble the commandline call, wrap at 70 characters and add the padding
    # white spaces before reassembling
    call_signature = " ".join(sys.argv)
    call_wrapped = [
        call_signature[i:i+linewidth]
        for i in range(0, len(call_signature), linewidth)]
    history_lines.append((" " * linepad).join(call_wrapped))
    # write history to the header
    cat.add_history("".join(history_lines))

    print("writing output file: %s" % args.o)
    cat.saveas(args.o, clobber=True)
