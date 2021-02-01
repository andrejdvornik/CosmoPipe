#!/usr/bin/env python2

###############
# @file ldacfilter.py
# @author Jan Luca van den Busch
# @date 19/11/2020
###############

###############
# NOTE: for portability this file ships a sub-set of "ldac.py"
#       authors: Douglas Applegate & Thomas Erben
#       version: 16.08.2015
#       description: utilities to make accessing LDAC cats easier within Python
###############

from __future__ import print_function, division
import os
import sys

import numpy
import tabeval
import astropy.io.fits as aif


class LDACCat(object):
    """
    Class to represent an LDAC catalogue
    """

    def __init__(self, cat=None):
        """
        An LDAC catalogue can be instantiated either as an empty catalogue
        or with an existing catalogue on disk.

        >>> a = ldac.LDACCat('mag.cat') # reads the catalogue 'mag.cat' into
                                        # the variable 'a'.
        """

        # The LDACCcat object contains a list of LDAC tables.  We
        # internally also keep the header of the PrimaryHDU. It is
        # reused when the catalogue is saved to a file.

        # for an empty catalogue this list is empty:
        self.ldactables = []
        self.header = None

        if cat != None:
            # read tables from a catalogue on disk:
            if type(cat) == type("a"):
                hdulist = aif.open(cat)

                for hdu in hdulist:
                    if isinstance(hdu, aif.PrimaryHDU) == True:
                        self.header = hdu.header
                    if isinstance(hdu, aif.BinTableHDU) == True:
                        self.ldactables.append(LDACTable(hdu))

    def __len__(self):
        """
        return the number of LDAC tables in this catalogue

        >>> b = len(a)  # number of LDAC tables in catalogue 'a'.
        """

        return len(self.ldactables)

    def __getitem__(self, tablename):
        """
        returns the named LDAC table. Returns 'None' if the table does
        not exist.

        Example:
        >>> b = a['OBJECTS'] # returns in 'b' the LDAC table with name
                             # 'OBJECTS' from catalogue 'a'
        """

        result = None
        for table in self.ldactables:
            if table.hdu.name == tablename:
                result = table

        return result

    def __setitem__(self, name, table):
        """
        adds or replaces an LDAC table in this catalogue

        >>> a['NEW_TABLE'] = b['OBJECTS'] # adds the new table 'NEW_TABLE' in
                                          # 'a' from table 'OBJECTS' in 'b'.
        """

        if isinstance(table, LDACTable):
            # check whether a table with name exists already:
            exists = False

            for i in xrange(len(self.ldactables)):
                if self.ldactables[i].hdu.name == name:
                    self.ldactables[i] = table
                    exists = True

            if exists == False:
                table.setname(name)
                self.ldactables.append(table)

    def tables(self):
        """
        returns the names of the contained LDAC tables

        >>> c = a.tables()  # gives a list of table names in catalogue 'a'
        """
        
        tablenames = []

        for table in self.ldactables:
            tablenames.append(table.hdu.name)

        return tablenames

    def __iter__(self):
        return self.ldactables.__iter__()

    def __contains__(self, tablename):
        """
        check whether a table with name 'tablename' is present
        in this catalogue
        """

        return tablename in self.tables()

    def add_history(self, keyvalue):
        """
        add a history keyword to the header of the catalogue

        >>> a.add_history('Catalogue created on 01/02/2013')
        """

        # create an empty header if necessary
        if self.header is None:
            self.header = aif.Header()
            
        # just delegate the work to an astropy method:    
        self.header.add_history('') # empty line for separation from other
                                    # comment/history lines
        self.header.add_history(keyvalue)

    def saveas(self, file, clobber=False):
        """
        save the LDAC catalogue to a file.

        if clobber=True an existing file is overwritten.

        >>> a.saveas('test.cat') # saves LDAC catalogue 'a' with all its
                                 # tables to file 'test.cat'
        """

        primaryHDU = aif.PrimaryHDU(header=self.header)
        hdulist = aif.HDUList([primaryHDU])

        for table in self.ldactables:
            if table.update == 1:
                table._update()

            hdulist.append(table.hdu)

        hdulist.writeto(file, clobber=clobber)
        
                
class LDACTable(object):
    """
    Class to represent an LDAC table
    """

    def __init__(self, hdu=None):
        """
        An LDAC table can be instantiated either as am empty table
        or with an astropy BinaryTable HDU (existing table).
        """

        if hdu is None:
            self.hdu = aif.BinTableHDU()
            self.hdu.data = None

            # We make sure that the table has 'some' proper name:
            self.hdu.name = "DEFAULT"
        else:
            self.hdu = hdu

        self.update = 0 # does the table need an update (e.g. when
                        # new columns were added?
    
    def __len__(self):
        """
        return the number of table entries (objects)
        """

        if self.update == 1:
            self._update()

        # 'self.hdu.data' leads to an exception for an empty catalogue.
        # Hence we check for this first:
        if self.hdu.size() == 0:
            return 0
        else:
            return len(self.hdu.data)

    def __getitem__(self, key):
        """
        returns the contents of an existing LDAC key as numpy array

        Example:
        >>> b = a['Xpos'] # store in 'b' the contents (numpy array)
                          # of key 'Xpos' from table 'a'.
        """

        if self.update == 1:
            self._update()

        if type(key) == type(5) or \
                type(key) == type(slice(5)):
            return self.hdu.data[key]

        if type(key) == type("a"):
            # we need to deal with slices through vector keys
            # such as 'MAG_APER(2)'
            startind = key.find("(")
            endind = key.find(")")

            if startind > 0 and endind > 0:
                keyname = key[:startind]
                keyindex = int(key[startind + 1:endind]) - 1

                try:
                   return self.hdu.data.field(keyname)[:,keyindex]
                except AttributeError:
                   raise KeyError(key) 
            else:
                try:
                    return self.hdu.data.field(key)
                except AttributeError:
                    raise KeyError(key)

        raise TypeError

    def __setitem__(self, key, val):
        """
        set values of an LDAC table

        a['Xpos'] = b # sets the key 'Xpos' in the table 'a' to the
                      # values in numpy array 'b'. If the key does
                      # not yet exist it is created.
        """
        # VERY uncomplete implementation for the moment!
        # - we only treat scalars for the moment!
        # - we do not check whether the key types match
        #   when an existing key is overwritten

        # sanity checks: the column name must be a string and
        # the value arrays length must match the table data
        # dimension:
        if type(key) == type("a"):
            # The first condition applies to an empty table:
            if self.hdu.data is None or len(val) == self.hdu.data.size:
                # If necessary add a new column to the table
                if self.__contains__(key) == True:
                    # quite some things might go wrong here
                    # (same data type, etc.)

                    # The following construct of '....(key)[:]' ensures
                    # a 'deep' copy of array element which we need here:
                    self.hdu.data.field(key)[:] = val
                else:
                    # determine format for the new column:
                    colformat=""
                    if numpy.issubdtype(val.dtype, float) == True:
                        colformat="1E"
                    
                    if numpy.issubdtype(val.dtype, int) == True:
                        colformat="1I"
                    
                    # now create the new column and create a 'new' table
                    # with the old plus the new column (I did not find a
                    # way to just append a new column to an existing
                    # table!):
                    newcolumn = aif.Column(name=key, format=colformat,
                                              array=val)
                    self.hdu.columns = self.hdu.columns + \
                        aif.ColDefs([newcolumn])

                    self.update = 1

        #raise NotImplementedError

    def __delitem__(self, key):
        raise NotImplementedError

    def _update(self):
        # update the table if necessary:
        newtabhdu = aif.BinTableHDU.from_columns(self.hdu.columns)
        newtabhdu.name = self.hdu.name
        self.hdu = newtabhdu
        self.update = 0

    def keys(self):
        """
        returns the names of the keys contained in this table

        >>> b = a.keys() # store a list of keynames of table 'a' in
                         # 'b'.
        """

        if self.update == 1:
            self._update()

        return self.hdu.columns.names

    def __iter__(self):
        if self.update == 1:
            self._update()

        return self.hdu.data.__iter__()

    def __contains__(self, item):
        if self.update == 1:
            self._update()

        return item in self.keys()

    def filter(self, mask):
        if self.update == 1:
            self._update()

        return LDACTable(aif.BinTableHDU(data=self.hdu.data[mask],
                                          header=self.hdu.header))

    def setname(self, name):
        """
        set/change the name of the LDAC table.

        >>> a.name = 'TESTTABLE' # set/change the name of the LDAC table
                                 # in 'a' to 'TESTTABLE'.
        """

        self.hdu.name = name


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
    cat = LDACCat(args.i)
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
