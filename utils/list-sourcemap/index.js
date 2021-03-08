const { SourceMapConsumer } = require('source-map');
const fs = require('fs');

const paths = process.argv.slice(2);

for (const path of paths) {
    const rawSourceMap = JSON.parse(fs.readFileSync(path));
    SourceMapConsumer.with(rawSourceMap, null, consumer => {
        // NOTE: the source-map library is one-based with line numbers,
        // and zero-based with column numbers.
        //
        // Since the sourcemap-v3 spec itself always talks about
        // zero-based numbers, I'm adjusting the output here to
        // always be zero-based.
        //
        consumer.eachMapping(mapping => console.log({
            source: mapping.source,
            generatedLine: mapping.generatedLine - 1,
            generatedColumn: mapping.generatedColumn,
            originalLine: mapping.originalLine - 1,
            originalColumn: mapping.originalColumn,
            name: mapping.name,
        }));
    });
}

console.log(process.argv);
