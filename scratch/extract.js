const fs = require('fs');
const readline = require('readline');

const rl = readline.createInterface({
  input: fs.createReadStream('C:/Users/chipr/.gemini/antigravity-ide/brain/61a4ff94-d92d-4302-b6dd-c9e589617539/.system_generated/logs/transcript_full.jsonl')
});

const steps = [642, 656, 668];
rl.on('line', (line) => {
  const obj = JSON.parse(line);
  if (steps.includes(obj.step_index)) {
    const file = obj.tool_calls[0].args.TargetFile;
    const content = obj.tool_calls[0].args.CodeContent;
    fs.mkdirSync('scratch/mock_backup', { recursive: true });
    const cleanFile = file.replace(/"/g, '');
    const basename = cleanFile.split(/[/\\]/).pop();
    const localName = 'scratch/mock_backup/' + basename;
    // content might have wrapping quotes or escape sequences
    let finalContent = content;
    if (finalContent.startsWith('"') && finalContent.endsWith('"')) {
      try {
        finalContent = JSON.parse(finalContent);
      } catch (e) {
        finalContent = finalContent.slice(1, -1).replace(/\\n/g, '\n').replace(/\\"/g, '"');
      }
    }
    fs.writeFileSync(localName, finalContent);
    console.log('Extracted:', basename);
  }
});
