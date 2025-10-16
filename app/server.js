const express = require('express');
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.VERSION || '1.0.0';
const COLOR = process.env.COLOR || 'unknown';

// Middleware
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Books database
const books = [
    { id: 1, title: "The DevOps Handbook", author: "Gene Kim", genre: "non-fiction", price: 34.99, emoji: "📘", description: "A comprehensive guide to implementing DevOps practices in your organization." },
    { id: 2, title: "Kubernetes in Action", author: "Marko Luksa", genre: "non-fiction", price: 44.99, emoji: "⚙️", description: "Master container orchestration with Kubernetes from basics to advanced concepts." },
    { id: 3, title: "The Phoenix Project", author: "Gene Kim", genre: "fiction", price: 29.99, emoji: "🔥", description: "A novel about IT, DevOps, and helping your business win." },
    { id: 4, title: "Clean Code", author: "Robert C. Martin", genre: "non-fiction", price: 39.99, emoji: "✨", description: "A handbook of agile software craftsmanship and writing better code." },
    { id: 5, title: "The Unicorn Project", author: "Gene Kim", genre: "fiction", price: 32.99, emoji: "🦄", description: "The follow-up to The Phoenix Project, focusing on developers and digital transformation." },
    { id: 6, title: "Site Reliability Engineering", author: "Google", genre: "non-fiction", price: 49.99, emoji: "🛠️", description: "How Google runs production systems, from the people who make it happen." },
    { id: 7, title: "Terraform: Up & Running", author: "Yevgeniy Brikman", genre: "non-fiction", price: 42.99, emoji: "🏗️", description: "Writing infrastructure as code with Terraform and automating deployments." },
    { id: 8, title: "Docker Deep Dive", author: "Nigel Poulton", genre: "non-fiction", price: 37.99, emoji: "🐳", description: "Master containerization with Docker from fundamentals to production." },
    { id: 9, title: "Continuous Delivery", author: "Jez Humble", genre: "non-fiction", price: 45.99, emoji: "🚀", description: "Reliable software releases through build, test, and deployment automation." },
    { id: 10, title: "The Pragmatic Programmer", author: "Andrew Hunt", genre: "non-fiction", price: 41.99, emoji: "💎", description: "Your journey to mastery in software craftsmanship and career development." },
    { id: 11, title: "Designing Data-Intensive Applications", author: "Martin Kleppmann", genre: "non-fiction", price: 54.99, emoji: "📊", description: "The big ideas behind reliable, scalable, and maintainable systems." },
    { id: 12, title: "Project Hail Mary", author: "Andy Weir", genre: "sci-fi", price: 27.99, emoji: "🚀", description: "A lone astronaut must save Earth from disaster in this thrilling sci-fi adventure." }
];

// API Routes
app.get('/api/books', (req, res) => {
    res.json(books);
});

app.get('/api/books/:id', (req, res) => {
    const book = books.find(b => b.id === parseInt(req.params.id));
    if (book) {
        res.json(book);
    } else {
        res.status(404).json({ error: 'Book not found' });
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

// Version endpoint
app.get('/version', (req, res) => {
    res.json({
        version: VERSION,
        color: COLOR,
        hostname: os.hostname(),
        buildNumber: process.env.BUILD_NUMBER || 'unknown'
    });
});

// API info endpoint
app.get('/api', (req, res) => {
    res.json({
        message: 'BookVerse API - Online Bookstore',
        version: VERSION,
        color: COLOR,
        hostname: os.hostname(),
        endpoints: { books: '/api/books', health: '/health', version: '/version' },
        stats: { totalBooks: books.length, uptime: process.uptime(), platform: os.platform() },
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, () => {
    console.log(`🚀 BookVerse Server running on port ${PORT}`);
    console.log(`📚 Version: ${VERSION}, Color: ${COLOR}`);
    console.log(`📖 Serving ${books.length} books`);
});
