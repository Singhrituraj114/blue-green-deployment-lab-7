// Shopping cart
let cart = [];

// Fetch and display deployment info
async function fetchDeploymentInfo() {
    try {
        const response = await fetch('/version');
        const data = await response.json();
        const banner = document.getElementById('deployment-banner');
        const info = document.getElementById('deployment-info');
        
        info.textContent = `🚀 Deployment: ${data.color.toUpperCase()} | Version: ${data.version} | Host: ${data.hostname || 'N/A'}`;
        banner.className = `deployment-banner ${data.color}`;
    } catch (error) {
        console.error('Error fetching deployment info:', error);
    }
}

// Fetch and display health status
async function fetchHealthStatus() {
    try {
        const response = await fetch('/health');
        const data = await response.json();
        document.getElementById('health-status').textContent = `✅ ${data.status} (${new Date(data.timestamp).toLocaleTimeString()})`;
    } catch (error) {
        document.getElementById('health-status').textContent = '❌ Unavailable';
    }
}

// Fetch and display books
async function fetchBooks() {
    try {
        const response = await fetch('/api/books');
        const books = await response.json();
        displayBooks(books);
    } catch (error) {
        console.error('Error fetching books:', error);
        document.getElementById('books-container').innerHTML = '<p>Error loading books. Please try again later.</p>';
    }
}

// Display books in the grid
function displayBooks(books) {
    const container = document.getElementById('books-container');
    container.innerHTML = books.map(book => `
        <div class="book-card" data-genre="${book.genre}">
            <div class="book-cover">${book.emoji}</div>
            <div class="book-title">${book.title}</div>
            <div class="book-author">by ${book.author}</div>
            <span class="book-genre">${book.genre}</span>
            <div class="book-description">${book.description}</div>
            <div class="book-footer">
                <span class="book-price">$${book.price.toFixed(2)}</span>
                <button class="add-to-cart-btn" onclick="addToCart(${book.id})">
                    Add to Cart
                </button>
            </div>
        </div>
    `).join('');
}

// Search books
function searchBooks() {
    const searchTerm = document.getElementById('search-input').value.toLowerCase();
    const cards = document.querySelectorAll('.book-card');
    
    cards.forEach(card => {
        const text = card.textContent.toLowerCase();
        card.style.display = text.includes(searchTerm) ? 'flex' : 'none';
    });
}

// Filter by genre
function filterByGenre() {
    const genre = document.getElementById('genre-filter').value;
    const cards = document.querySelectorAll('.book-card');
    
    cards.forEach(card => {
        if (genre === 'all' || card.dataset.genre === genre) {
            card.style.display = 'flex';
        } else {
            card.style.display = 'none';
        }
    });
}

// Add to cart
async function addToCart(bookId) {
    try {
        const response = await fetch('/api/books');
        const books = await response.json();
        const book = books.find(b => b.id === bookId);
        
        if (book) {
            cart.push(book);
            updateCartCount();
            showNotification(`"${book.title}" added to cart!`);
        }
    } catch (error) {
        console.error('Error adding to cart:', error);
    }
}

// Update cart count
function updateCartCount() {
    document.getElementById('cart-count').textContent = cart.length;
}

// Toggle cart modal
function toggleCart() {
    const modal = document.getElementById('cart-modal');
    if (modal.style.display === 'block') {
        modal.style.display = 'none';
    } else {
        displayCartItems();
        modal.style.display = 'block';
    }
}

// Display cart items
function displayCartItems() {
    const container = document.getElementById('cart-items');
    
    if (cart.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #7f8c8d; padding: 20px;">Your cart is empty</p>';
        document.getElementById('cart-total').textContent = '0.00';
        return;
    }
    
    container.innerHTML = cart.map((book, index) => `
        <div class="cart-item">
            <div class="cart-item-info">
                <div class="cart-item-title">${book.title}</div>
                <div class="cart-item-price">$${book.price.toFixed(2)}</div>
            </div>
            <button class="remove-item-btn" onclick="removeFromCart(${index})">Remove</button>
        </div>
    `).join('');
    
    const total = cart.reduce((sum, book) => sum + book.price, 0);
    document.getElementById('cart-total').textContent = total.toFixed(2);
}

// Remove from cart
function removeFromCart(index) {
    cart.splice(index, 1);
    updateCartCount();
    displayCartItems();
}

// Checkout
function checkout() {
    if (cart.length === 0) {
        showNotification('Your cart is empty!', 'warning');
        return;
    }
    
    const total = cart.reduce((sum, book) => sum + book.price, 0);
    showNotification(`Order placed! Total: $${total.toFixed(2)}. Thank you for shopping with BookVerse! 🎉`, 'success');
    
    cart = [];
    updateCartCount();
    toggleCart();
}

// Show notification
function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.style.cssText = `
        position: fixed;
        top: 80px;
        right: 20px;
        background: ${type === 'success' ? '#27ae60' : '#f39c12'};
        color: white;
        padding: 15px 25px;
        border-radius: 10px;
        box-shadow: 0 4px 15px rgba(0,0,0,0.3);
        z-index: 3000;
        animation: slideIn 0.3s ease;
    `;
    notification.textContent = message;
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// Close modal when clicking outside
window.onclick = function(event) {
    const modal = document.getElementById('cart-modal');
    if (event.target === modal) {
        modal.style.display = 'none';
    }
}

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from { transform: translateX(400px); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }
    @keyframes slideOut {
        from { transform: translateX(0); opacity: 1; }
        to { transform: translateX(400px); opacity: 0; }
    }
`;
document.head.appendChild(style);

// Initialize app
document.addEventListener('DOMContentLoaded', () => {
    fetchDeploymentInfo();
    fetchHealthStatus();
    fetchBooks();
    
    // Refresh health status every 30 seconds
    setInterval(fetchHealthStatus, 30000);
    
    // Refresh deployment info every 10 seconds to catch blue-green switches
    setInterval(fetchDeploymentInfo, 10000);
});
