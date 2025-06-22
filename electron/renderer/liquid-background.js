console.log('Loading liquid background...');

class LiquidBackground {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        this.canvas = null;
        this.ctx = null;
        this.animationId = null;
        this.blobs = [];
        this.init();
    }

    init() {
        // Create canvas
        this.canvas = document.createElement('canvas');
        this.canvas.style.position = 'fixed';
        this.canvas.style.top = '0';
        this.canvas.style.left = '0';
        this.canvas.style.width = '100%';
        this.canvas.style.height = '100%';
        this.canvas.style.zIndex = '-1';
        this.canvas.style.pointerEvents = 'none';
        
        this.ctx = this.canvas.getContext('2d');
        
        // Add to container or body
        if (this.container) {
            this.container.appendChild(this.canvas);
        } else {
            document.body.appendChild(this.canvas);
        }
        
        // Set up resize handler
        this.handleResize = this.handleResize.bind(this);
        window.addEventListener('resize', this.handleResize);
        
        // Initial setup
        this.handleResize();
        this.createBlobs();
        this.animate();
    }

    handleResize() {
        const dpr = window.devicePixelRatio || 1;
        this.canvas.width = window.innerWidth * dpr;
        this.canvas.height = window.innerHeight * dpr;
        this.ctx.scale(dpr, dpr);
        this.canvas.style.width = window.innerWidth + 'px';
        this.canvas.style.height = window.innerHeight + 'px';
    }

    createBlobs() {
        this.blobs = [];
        const blobCount = 8;
        
        for (let i = 0; i < blobCount; i++) {
            this.blobs.push({
                x: Math.random() * window.innerWidth,
                y: Math.random() * window.innerHeight,
                radius: 80 + Math.random() * 120,
                vx: (Math.random() - 0.5) * 0.5,
                vy: (Math.random() - 0.5) * 0.5,
                hue: 200 + Math.random() * 60, // Blue to purple range
                opacity: 0.02 + Math.random() * 0.03
            });
        }
    }

    animate() {
        this.ctx.clearRect(0, 0, window.innerWidth, window.innerHeight);
        
        // Update and draw blobs
        this.blobs.forEach(blob => {
            // Update position
            blob.x += blob.vx;
            blob.y += blob.vy;
            
            // Bounce off edges
            if (blob.x < -blob.radius || blob.x > window.innerWidth + blob.radius) {
                blob.vx *= -1;
            }
            if (blob.y < -blob.radius || blob.y > window.innerHeight + blob.radius) {
                blob.vy *= -1;
            }
            
            // Slowly change hue
            blob.hue += 0.1;
            if (blob.hue > 280) blob.hue = 200;
            
            // Create gradient
            const gradient = this.ctx.createRadialGradient(
                blob.x, blob.y, 0,
                blob.x, blob.y, blob.radius
            );
            gradient.addColorStop(0, `hsla(${blob.hue}, 70%, 80%, ${blob.opacity})`);
            gradient.addColorStop(1, `hsla(${blob.hue}, 70%, 80%, 0)`);
            
            // Draw blob
            this.ctx.fillStyle = gradient;
            this.ctx.beginPath();
            this.ctx.arc(blob.x, blob.y, blob.radius, 0, Math.PI * 2);
            this.ctx.fill();
        });
        
        this.animationId = requestAnimationFrame(() => this.animate());
    }

    destroy() {
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
        }
        if (this.canvas && this.canvas.parentNode) {
            this.canvas.parentNode.removeChild(this.canvas);
        }
        window.removeEventListener('resize', this.handleResize);
    }
}

// Make available globally
window.LiquidBackground = LiquidBackground;