import resolve from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import terser from '@rollup/plugin-terser';
import pkg from './package.json' with { type: "json" };

const isViewer = process.env.BUILD === 'viewer';

export default isViewer ? 
	// MarkupViewer - read-only viewer UMD build
	{
		input: 'src/jsViewer/main.js',
		output: {
			file: 'dist/markupviewer.umd.js',
			format: 'umd',
			name: 'MV'  // so we can call MV.<exported function> from Swift
		},
		plugins: [
			resolve(),
			commonjs()
		],
		treeshake: true  // Enable tree shaking for smaller bundle
	} : 
	// MarkupEditor - browser-friendly UMD build (default)
	{
		input: 'src/js/main.js',
		output: {
			file: pkg.browser,
			format: 'umd',
            name: 'MU'  // so we can call MU.<exported function> from Swift
		},
		plugins: [
			resolve(),
			commonjs()
		]
	};
