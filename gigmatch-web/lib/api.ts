import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios';

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'https://gigmatch.onrender.com';
const API_URL = `${API_BASE}/api/v1`;

export const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true,
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('accessToken') : null;
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for token refresh
api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean };
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        const refreshToken = localStorage.getItem('refreshToken');
        if (refreshToken) {
          const response = await axios.post(`${API_URL}/auth/refresh`, { refreshToken });
          const { accessToken, refreshToken: newRefreshToken } = response.data;
          
          localStorage.setItem('accessToken', accessToken);
          localStorage.setItem('refreshToken', newRefreshToken);
          
          if (originalRequest.headers) {
            originalRequest.headers.Authorization = `Bearer ${accessToken}`;
          }
          return api(originalRequest);
        }
      } catch {
        // Refresh failed, clear tokens and redirect to login
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('user');
        if (typeof window !== 'undefined') {
          window.location.href = '/login';
        }
      }
    }
    
    return Promise.reject(error);
  }
);

// API Endpoints
export const endpoints = {
  // Auth
  auth: {
    register: '/auth/register',
    login: '/auth/login',
    logout: '/auth/logout',
    refresh: '/auth/refresh',
    forgotPassword: '/auth/forgot-password',
    resetPassword: '/auth/reset-password',
    verifyEmail: '/auth/verify-email',
    resendVerification: '/auth/resend-verification',
    profile: '/auth/profile',
    me: '/auth/me',
    changePassword: '/auth/change-password',
  },
  // Artists
  artists: {
    list: '/artists',
    get: (id: string) => `/artists/${id}`,
    update: (id: string) => `/artists/${id}`,
    setup: '/artists/setup',
  },
  // Venues
  venues: {
    list: '/venues',
    get: (id: string) => `/venues/${id}`,
    update: (id: string) => `/venues/${id}`,
    setup: '/venues/setup',
  },
  // Discovery
  discovery: {
    cards: '/discovery/cards',
    like: (id: string) => `/discovery/like/${id}`,
    pass: (id: string) => `/discovery/pass/${id}`,
  },
  // Matches
  matches: {
    list: '/matches',
    get: (id: string) => `/matches/${id}`,
    archive: (id: string) => `/matches/${id}/archive`,
    block: (id: string) => `/matches/${id}/block`,
  },
  // Messages
  messages: {
    list: (matchId: string) => `/messages?matchId=${matchId}`,
    send: '/messages',
    markRead: (id: string) => `/messages/${id}/read`,
  },
  // Subscriptions
  subscriptions: {
    current: '/subscriptions/current',
    plans: '/subscriptions/plans',
    create: '/subscriptions/create',
    checkout: '/subscriptions/checkout',
    portal: '/subscriptions/portal',
    cancel: '/subscriptions/cancel',
    webhook: '/subscriptions/webhook',
  },
  // Admin
  admin: {
    dashboard: '/admin/dashboard',
    users: '/admin/users',
    artists: '/admin/artists',
    venues: '/admin/venues',
    matches: '/admin/matches',
    subscriptions: '/admin/subscriptions',
    reports: '/admin/reports',
  },
};

export default api;
