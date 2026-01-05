const http = require('http');

http.get('http://localhost:4000/api/movies?limit=5', (resp) => {
    let data = '';

    resp.on('data', (chunk) => {
        data += chunk;
    });

    resp.on('end', () => {
        try {
            const json = JSON.parse(data);
            console.log('Success:', json.success);
            if (json.data) {
                json.data.forEach(m => {
                    console.log(`Movie: ${m.name}`);
                    console.log(` - poster_url: ${m.poster_url}`);
                    console.log(` - thumb_url: ${m.thumb_url}`);
                });
            }
        } catch (e) {
            console.error('Error parsing JSON:', e.message);
        }
    });

}).on("error", (err) => {
    console.log("Error: " + err.message);
});
