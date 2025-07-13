console.log('Promise Keeper config.js loading...');

// Supabase configuration
const SUPABASE_URL = "https://msucqyacicicjkakvurq.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zdWNxeWFjaWNpY2prYWt2dXJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjcyMDgsImV4cCI6MjA2NjEwMzIwOH0.dqV_-pUx8yJbyv2m1c-O5syFoKERKLEF0bDimtv0lro";

// Create Supabase client using the global supabase object
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Test connection
console.log('Supabase client initialized:', { 
    url: SUPABASE_URL, 
    hasKey: !!SUPABASE_ANON_KEY 
});

// API Configuration
const API_CONFIG = {
    // Base URLs
    baseUrl: window.electronAPI?.env?.API_BASE_URL_OVERRIDE || "https://promise-keeper-api-summer-water-1765.fly.dev",
    
    // API Endpoints
    endpoints: {
        extractPromisesFile: "/extract_promises_file",
        extractPromisesFileAuth: "/extract_promises_file_auth"
    },
    
    // Build full URL
    getUrl(endpoint) {
        return this.baseUrl + endpoint;
    }
};

// Make available globally
window.PromiseKeeperConfig = {
    SUPABASE_URL,
    SUPABASE_ANON_KEY,
    supabaseClient,
    API_CONFIG
}; 