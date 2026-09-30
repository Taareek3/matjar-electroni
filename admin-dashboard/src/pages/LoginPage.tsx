import { useState, type FormEvent } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { ChefHat, Eye, EyeOff, Lock, Mail, UtensilsCrossed } from "lucide-react";
import { useAuth } from "../auth/AuthContext";
import { Button, Field, inputClass, Spinner } from "../components/ui";

export function LoginPage() {
  const { token, login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState("taareek31@gmail.com");
  const [password, setPassword] = useState("tarek1122334455");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  if (token) {
    return <Navigate to="/" replace />;
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await login(email.trim(), password);
      navigate("/", { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : "تعذر تسجيل الدخول");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-slate-900 via-indigo-950 to-violet-900 p-4">
      <div className="animate-fade-in w-full max-w-md">
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-3xl bg-gradient-to-br from-indigo-500 to-violet-600 shadow-2xl shadow-indigo-500/40">
            <UtensilsCrossed className="h-8 w-8 text-white" />
          </div>
          <h1 className="text-2xl font-extrabold text-white">
            لوحة تحكم المطعم
          </h1>
          <p className="mt-1 text-sm text-indigo-200">
            سجّل الدخول لإدارة الطلبات والمنيو
          </p>
        </div>

        <form
          onSubmit={handleSubmit}
          className="space-y-4 rounded-3xl border border-white/10 bg-white/95 p-7 shadow-2xl backdrop-blur"
        >
          <Field label="البريد الإلكتروني">
            <div className="relative">
              <Mail className="absolute top-1/2 right-3.5 h-4.5 w-4.5 h-5 w-5 -translate-y-1/2 text-slate-400" />
              <input
                type="email"
                dir="ltr"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                className={`${inputClass} ps-10 text-start`}
                placeholder="admin@example.com"
                required
                autoComplete="username"
              />
            </div>
          </Field>

          <Field label="كلمة المرور">
            <div className="relative">
              <Lock className="absolute top-1/2 right-3.5 h-5 w-5 -translate-y-1/2 text-slate-400" />
              <input
                type={showPassword ? "text" : "password"}
                dir="ltr"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                className={`${inputClass} px-10 text-start`}
                placeholder="••••••••"
                required
                autoComplete="current-password"
              />
              <button
                type="button"
                onClick={() => setShowPassword((value) => !value)}
                className="absolute top-1/2 left-3.5 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                aria-label="إظهار كلمة المرور"
              >
                {showPassword ? (
                  <EyeOff className="h-5 w-5" />
                ) : (
                  <Eye className="h-5 w-5" />
                )}
              </button>
            </div>
          </Field>

          {error && (
            <div className="rounded-xl bg-rose-50 px-4 py-3 text-sm font-bold text-rose-600 ring-1 ring-inset ring-rose-100">
              {error}
            </div>
          )}

          <Button type="submit" disabled={loading} className="w-full">
            {loading && <Spinner className="h-4 w-4" />}
            دخول
          </Button>

          <div className="flex items-center justify-center gap-2 rounded-xl bg-slate-50 px-4 py-2.5 text-xs text-slate-500">
            <ChefHat className="h-4 w-4" />
             الحساب الافتراضي: taareek31@gmail.com / tarek1122334455
          </div>
        </form>
      </div>
    </div>
  );
}
