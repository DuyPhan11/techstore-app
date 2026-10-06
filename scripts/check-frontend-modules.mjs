import { SourceTextModule } from 'node:vm';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../frontend/', import.meta.url));
async function files(directory) {
    const result = [];
    for (const entry of await readdir(directory, { withFileTypes: true })) {
        const name = path.join(directory, entry.name);
        if (entry.isDirectory()) result.push(...await files(name));
        else if (name.endsWith('.js')) result.push(name);
    }
    return result;
}

const sources = await files(root);
for (const entry of sources) {
    const modules = new Map();
    async function load(filename) {
        if (!modules.has(filename)) {
            modules.set(filename, new SourceTextModule(await readFile(filename, 'utf8'), { identifier: filename }));
        }
        return modules.get(filename);
    }
    const module = await load(entry);
    await module.link((specifier, parent) => {
        if (!specifier.startsWith('.')) throw new Error(`Unexpected external import: ${specifier}`);
        return load(path.resolve(path.dirname(parent.identifier), specifier));
    });
}
console.log(`All ${sources.length} frontend modules linked successfully (imports and exports checked).`);
