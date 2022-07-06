import { build, BuildOptions } from 'esbuild';
import fs from 'fs';
import archiver from 'archiver';
import * as modules from './src/index';

const basePath = './src/{0}.ts';
const outDir = './dist';
const outPath = `${outDir}/{0}.esm.js`;

const sharedOptions: BuildOptions = {
  bundle: true,
  logLevel: 'info',
  minify: true,
  sourcemap: true,
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
      moduleName,
    };
  })
  .map(async ({ moduleName, ...options }) => {
    const { outfile } = options;
    await build({
      ...sharedOptions,
      ...options,
    });
    return { outfile, moduleName };
  });

Promise.all(builds).then(async (results) => {
  return results.map(({ outfile, moduleName }) => {
    const src = {
      fileName: `${process.cwd()}/${outfile}`,
      name: `${moduleName}.js`,
    };
    const srcMap = {
      fileName: `${src.fileName}.map`,
      name: `${moduleName}.js.map`,
    };
    const dst = `${process.cwd()}/${outDir}/${moduleName}.zip`;
    const archive = archiver('zip', {
      zlib: { level: 9 },
    });
    archive.pipe(fs.createWriteStream(dst));
    archive.append(fs.createReadStream(src.fileName), { name: src.name });
    archive.append(fs.createReadStream(srcMap.fileName), { name: srcMap.name });
    return archive.finalize();
  });
});
