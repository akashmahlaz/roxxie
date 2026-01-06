import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import api, { endpoints } from './api';

export interface User {
  id: string;
  email: string;
  fullName: string;
  role: 'artist' | 'venue' | 'admin';
  profileId?: string;
  photo?: string;
  hasCompletedSetup: boolean;
  isEmailVerified: boolean;
}

interface AuthState {
  user: User | null;
  accessToken: string | null;
  refreshToken: string | null;
  isLoading: boolean;
  error: string | null;
  
  // Actions
  setUser: (user: User | null) => void;
  setTokens: (accessToken: string, refreshToken: string) => void;
  login: (email: string, password: string) => Promise<void>;
  register: (data: RegisterData) => Promise<void>;
  logout: () => Promise<void>;
  forgotPassword: (email: string) => Promise<void>;
  resetPassword: (token: string, newPassword: string) => Promise<void>;
  verifyEmail: (token: string) => Promise<void>;
  clearError: () => void;
}

export interface RegisterData {
  email: string;
  password: string;
  fullName: string;
  role: 'artist' | 'venue';
  phone?: string;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      refreshToken: null,
      isLoading: false,
      error: null,

      setUser: (user) => set({ user }),
      
      setTokens: (accessToken, refreshToken) => {
        localStorage.setItem('accessToken', accessToken);
        localStorage.setItem('refreshToken', refreshToken);
        set({ accessToken, refreshToken });
      },

      login: async (email: string, password: string) => {
        set({ isLoading: true, error: null });
        try {
          const response = await api.post(endpoints.auth.login, { email, password });
          const { accessToken, refreshToken, user } = response.data;
          
          localStorage.setItem('accessToken', accessToken);
          localStorage.setItem('refreshToken', refreshToken);
          
          set({ 
            user, 
            accessToken, 
            refreshToken, 
            isLoading: false 
          });
        } catch (error: unknown) {
          const err = error as { response?: { data?: { message?: string } } };
          set({ 
            error: err.response?.data?.message || 'Login failed', 
            isLoading: false 
          });
          throw error;
        }
      },

      register: async (data: RegisterData) => {
        set({ isLoading: true, error: null });
        try {
          const response = await api.post(endpoints.auth.register, data);
          const { accessToken, refreshToken, user } = response.data;
          
          localStorage.setItem('accessToken', accessToken);
          localStorage.setItem('refreshToken', refreshToken);
          
          set({ 
            user, 
            accessToken, 
            refreshToken, 
            isLoading: false 
          });
        } catch (error: unknown) {
          const err = error as { response?: { data?: { message?: string } } };
          set({ 
            error: err.response?.data?.message || 'Registration failed', 
            isLoading: false 
          });
          throw error;
        }
      },

      logout: async () => {
        try {
          await api.post(endpoints.auth.logout);
        } catch {
          // Ignore logout errors
        } finally {
          localStorage.removeItem('accessToken');
          localStorage.removeItem('refreshToken');
          set({ user: null, accessToken: null, refreshToken: null });
        }
      },

      forgotPassword: async (email: string) => {
        set({ isLoading: true, error: null });
        try {
          await api.post(endpoints.auth.forgotPassword, { email });
          set({ isLoading: false });
        } catch (error: unknown) {
          const err = error as { response?: { data?: { message?: string } } };
          set({ 
            error: err.response?.data?.message || 'Failed to send reset email', 
            isLoading: false 
          });
          throw error;
        }
      },

      resetPassword: async (token: string, newPassword: string) => {
        set({ isLoading: true, error: null });
        try {
          await api.post(endpoints.auth.resetPassword, { token, newPassword });
          set({ isLoading: false });
        } catch (error: unknown) {
          const err = error as { response?: { data?: { message?: string } } };
          set({ 
            error: err.response?.data?.message || 'Failed to reset password', 
            isLoading: false 
          });
          throw error;
        }
      },

      verifyEmail: async (token: string) => {
        set({ isLoading: true, error: null });
        try {
          await api.post(endpoints.auth.verifyEmail, { token });
          set((state) => ({
            user: state.user ? { ...state.user, isEmailVerified: true } : null,
            isLoading: false
          }));
        } catch (error: unknown) {
          const err = error as { response?: { data?: { message?: string } } };
          set({ 
            error: err.response?.data?.message || 'Email verification failed', 
            isLoading: false 
          });
          throw error;
        }
      },

      clearError: () => set({ error: null }),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({ 
        user: state.user, 
        accessToken: state.accessToken, 
        refreshToken: state.refreshToken 
      }),
    }
  )
);
