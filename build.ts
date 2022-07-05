import { build, BuildOptions } from 'esbuild';
import { zip } from 'compressing';
import { dependencies } from './package.json';
import * as modules from './src/index';

const basePath = './src/{0}.ts';
const outPath = './dist/{0}.esm.js';

const sharedOptions: BuildOptions = {
  bundle: true,
  logLevel: 'info',
  minify: true,
  sourcemap: false,
  external: Object.keys(dependencies),
  platform: 'node',
  target: ['es2020'],
};

const builds = Object.keys(modules)
  .map((moduleName) => {
    const entryPoints = [basePath.replace('{0}', moduleName)];
    const outfile = outPath.replace('{0}', moduleName);
    return {
      entryPoints,
      outfile,
    };
  })
  .map(async (options) => {
    const { outfile } = options;
    await build({
      ...sharedOptions,
      ...options,
    });
    return outfile;
  });

Promise.all(builds).then(async (buildFiles) => {
  return buildFiles.map((buildFile) => {
    const src = `${process.cwd()}/${buildFile}`;
    const dst = `${src}.zip`;
    return zip.compressFile(src, dst);
  });
});
