#!/usr/bin/env python

import os, os.path, re, shutil, sys

class Changelog(list):
    _rules = r"""
^
(?P<source>
    \w[-+0-9a-z.]+
)
\ 
\(
(?P<version>
    [^\(\)\ \t]+
)
\)
\s+
(?P<distribution>
    [-+0-9a-zA-Z.]+
)
\;
"""
    _re = re.compile(_rules, re.X)

    class Entry(object):
        __slot__ = 'distribution', 'source', 'version'

        def __init__(self, distribution, source, version):
            self.distribution, self.source, self.version = distribution, source, version

    def __init__(self, dir):
        f = file(os.path.join(dir, "debian/changelog"))
        while True:
            line = f.readline()
            if not line:
                break
            match = self._re.match(line)
            if not match:
                continue
            self.append(self.Entry(match.group('distribution'), match.group('source'), match.group('version')))

class GenOrig(object):
    log = sys.stdout.write

    def __init__(self, root, orig, input_tar, version):
        self.orig, self.input_tar, self.version = orig, input_tar, version

        changelog = Changelog(root)
        self.source = changelog[0].source

    def __call__(self):
        import tempfile
        self.dir = tempfile.mkdtemp(prefix = 'genorig', dir = 'debian')
        try:
            self.orig_dir = "%s-%s" % (self.source, self.version)
            self.orig_tar = "%s_%s.orig.tar.gz" % (self.source, self.version)

            self.do_upstream()
            self.do_orig()
        finally:
            shutil.rmtree(self.dir)

    def do_upstream(self):
        self.log("Extracting tarball %s\n" % self.input_tar)
        match = re.match(r'(^|.*/)(?P<dir>[^/]+)\.(t|tar\.)(?P<extension>(gz|bz2))$', self.input_tar)
        if not match:
            raise RuntimeError("Can't identify name of tarball")
        cmdline = ['tar -xf', self.input_tar, '-C', self.dir]
        extension = match.group('extension')
        if extension == 'bz2':
            cmdline.append('-j')
        elif extension == 'gz':
            cmdline.append('-z')
        if os.spawnv(os.P_WAIT, '/bin/sh', ['sh', '-c', ' '.join(cmdline)]):
            raise RuntimeError("Can't extract tarball")
        os.rename(os.path.join(self.dir, match.group('dir')), os.path.join(self.dir, self.orig_dir))

    def do_orig(self):
        self.log("Generating tarball %s\n" % self.orig_tar)
        out = os.path.join(self.orig, self.orig_tar)

        try:
            os.mkdir(self.orig)
        except OSError: pass
        try:
            os.stat(out)
        except OSError: pass
        else:
            raise RuntimeError("Destination already exists (%s)" % out)

        cmdline = ['tar -czf', out, '-C', self.dir, self.orig_dir]
        try:
            if os.spawnv(os.P_WAIT, '/bin/sh', ['sh', '-c', ' '.join(cmdline)]):
                raise RuntimeError("Can't patch source")
            os.chmod(out, 0644)
        except:
            try:
                os.unlink(out)
            except OSError:
                pass
            raise

if __name__ == '__main__':
    from optparse import OptionParser
    p = OptionParser(usage = "%prog TAR VERSION")
    options, args = p.parse_args(sys.argv)

    if len(args) < 2:
        raise RuntimeError("Need more arguments")

    root = os.path.realpath(os.path.join(sys.path[0], '..', '..'))
    orig = os.path.realpath(os.path.join(root, '..', 'orig'))
    input_tar = args[1]
    version = args[2]

    GenOrig(root, orig, input_tar, version)()
