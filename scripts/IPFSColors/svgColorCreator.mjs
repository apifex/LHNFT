import * as d3 from 'd3';
import fs from 'fs';
import { JSDOM } from 'jsdom';
import { createRequire } from "module";
const require = createRequire(import.meta.url);
const colors = require('./256-colors.json');

async function createColors() {
    const dom = new JSDOM(`<!DOCTYPE html><body></body>`);
    let body = d3.select(dom.window.document.querySelector("body"))
    let svg = body.append('svg').attr('width', 100).attr('height', 100).attr('xmlns', 'http://www.w3.org/2000/svg');
    for (let i = 0; i < colors.length; i++) {
        svg.append("rect")
            .attr("x", 10)
            .attr("y", 10)
            .attr("width", 80)
            .attr("height", 80)
            .style("fill", `${colors[i].hexString}`);
        fs.writeFileSync(`./colors/${colors[i].colorId}.svg`, body.html());
        let rect = d3.select(dom.window.document.querySelector("rect"))
        rect.remove()
    }
}

export default createColors;




