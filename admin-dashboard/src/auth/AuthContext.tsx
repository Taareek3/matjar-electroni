import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { api, extractError, type ApiEnvelope } from "../lib/api";
import type { AdminUser } from "../types";

interface AuthContextValue {
  user: AdminUser | null;
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function readStoredUser(): AdminUser | null {
  const raw = localStorage.getItem("admin_user");
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AdminUser;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(
    () => localStorage.getItem("admin_token"),
  );
  const [user, setUser] = useState<AdminUser | null>(readStoredUser);

  useEffect(() => {
    if (!token) return;
    api
      .get<ApiEnvelope<unknown>>("/auth/me")
      .then(() => {})
      .catch(() => {
        localStorage.removeItem("admin_token");
        localStorage.removeItem("admin_user");
        setToken(null);
        setUser(null);
      });
  }, [token]);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      token,
      async login(email, password) {
        try {
          const { data } = await api.post<
            ApiEnvelope<{ token: string; user: AdminUser }>
          >("/auth/login", { email, password });

          const { token: nextToken, user: nextUser } = data.data;

          if (nextUser.role !== "ADMIN" && nextUser.role !== "KITCHEN_STAFF") {
            throw new Error("هذا الحساب لا يملك صلاحية الوصول للوحة التحكم");
          }

          localStorage.setItem("admin_token", nextToken);
          localStorage.setItem("admin_user", JSON.stringify(nextUser));
          setToken(nextToken);
          setUser(nextUser);
        } catch (error) {
          if (error instanceof Error && !("isAxiosError" in error)) {
            throw error;
          }
          throw new Error(extractError(error));
        }
      },
      logout() {
        localStorage.removeItem("admin_token");
        localStorage.removeItem("admin_user");
        setToken(null);
        setUser(null);
      },
    }),
    [user, token],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within AuthProvider");
  }
  return context;
}
