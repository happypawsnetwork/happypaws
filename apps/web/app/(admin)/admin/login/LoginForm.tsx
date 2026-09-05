"use client";

import {
  useState,
  useRef,
  useEffect,
  KeyboardEvent,
  ClipboardEvent,
} from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import Link from "next/link";
import { loginAction, verifyOtpAction } from "@/actions/auth";

function EyeIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  );
}

function EyeOffIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      <path d="M9.88 9.88a3 3 0 1 0 4.24 4.24" />
      <path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68" />
      <path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61" />
      <line x1="2" x2="22" y1="2" y2="22" />
    </svg>
  );
}

function LoaderIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      <path d="M21 12a9 9 0 1 1-6.219-8.56" />
    </svg>
  );
}

function ArrowLeftIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      <path d="m12 19-7-7 7-7" />
      <path d="M19 12H5" />
    </svg>
  );
}

export default function LoginForm() {
  const router = useRouter();
  const [step, setStep] = useState<"login" | "otp">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [verificationToken, setVerificationToken] = useState("");

  // OTP State
  const [otpValues, setOtpValues] = useState<string[]>(Array(6).fill(""));
  const [focusedIndex, setFocusedIndex] = useState<number | null>(null);
  const otpRefs = useRef<(HTMLInputElement | null)[]>([]);

  // Resend Countdown State
  const [resendCountdown, setResendCountdown] = useState(0);
  const [resendAttempt, setResendAttempt] = useState(1);
  const [otpExpiresIn, setOtpExpiresIn] = useState(0);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let timer: NodeJS.Timeout;
    if (resendCountdown > 0) {
      timer = setInterval(() => {
        setResendCountdown((prev) => prev - 1);
      }, 1000);
    }
    return () => clearInterval(timer);
  }, [resendCountdown]);

  useEffect(() => {
    let timer: NodeJS.Timeout;
    if (step === "otp" && otpExpiresIn > 0) {
      timer = setInterval(() => {
        setOtpExpiresIn((prev) => prev - 1);
      }, 1000);
    }
    return () => clearInterval(timer);
  }, [step, otpExpiresIn]);

  useEffect(() => {
    if (step === "otp") {
      const focusTimer = setTimeout(() => {
        otpRefs.current[0]?.focus();
      }, 150);
      return () => clearTimeout(focusTimer);
    }
  }, [step]);

  const handleLogin = async (e?: React.FormEvent, isResend = false) => {
    if (e) e.preventDefault();
    setIsLoading(true);
    setError("");

    try {
      const data = await loginAction(email, password, rememberMe);

      if (data.devBypass) {
        router.push("/admin");
        return;
      }

      setVerificationToken(data.verificationToken);

      if (isResend) {
        setOtpValues(Array(6).fill(""));
        setResendCountdown(30 * resendAttempt);
        setResendAttempt((prev) => prev + 1);
        setOtpExpiresIn(300);
        otpRefs.current[0]?.focus();
      } else {
        setStep("otp");
        setOtpExpiresIn(300);
      }
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError("An unexpected error occurred.");
      }
    } finally {
      setIsLoading(false);
    }
  };

  const submitOtp = async (codeToVerify: string) => {
    if (codeToVerify.length !== 6 || isLoading) return;

    setIsLoading(true);
    setError("");

    try {
      await verifyOtpAction(verificationToken, codeToVerify);
      router.push("/admin");
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError("An unexpected error occurred.");
      }
      setIsLoading(false);
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    await submitOtp(otpValues.join(""));
  };

  const handleOtpChange = (index: number, rawValue: string) => {
    const digitsOnly = rawValue.replace(/\D/g, "");
    if (!digitsOnly) {
      const newOtp = [...otpValues];
      newOtp[index] = "";
      setOtpValues(newOtp);
      return;
    }

    const newOtp = [...otpValues];
    // Pick the latest digit typed
    const digit = digitsOnly.slice(-1);
    newOtp[index] = digit;
    setOtpValues(newOtp);

    // Auto-focus next input
    if (index < 5) {
      otpRefs.current[index + 1]?.focus();
    }

    // Auto submit if all 6 digits are filled
    const fullCode = newOtp.join("");
    if (fullCode.length === 6 && !newOtp.includes("")) {
      submitOtp(fullCode);
    }
  };

  const handleOtpKeyDown = (
    index: number,
    e: KeyboardEvent<HTMLInputElement>,
  ) => {
    if (e.key === "Backspace") {
      if (!otpValues[index] && index > 0) {
        otpRefs.current[index - 1]?.focus();
        const newOtp = [...otpValues];
        newOtp[index - 1] = "";
        setOtpValues(newOtp);
      }
    } else if (e.key === "ArrowLeft" && index > 0) {
      otpRefs.current[index - 1]?.focus();
    } else if (e.key === "ArrowRight" && index < 5) {
      otpRefs.current[index + 1]?.focus();
    }
  };

  const handleOtpPaste = (e: ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const pastedData = e.clipboardData
      .getData("text")
      .replace(/\D/g, "")
      .slice(0, 6);
    if (!pastedData) return;

    const newOtp = [...otpValues];
    for (let i = 0; i < pastedData.length; i++) {
      newOtp[i] = pastedData[i];
    }
    setOtpValues(newOtp);

    const nextIndex = Math.min(pastedData.length, 5);
    otpRefs.current[nextIndex]?.focus();

    if (pastedData.length === 6) {
      submitOtp(pastedData);
    }
  };

  const inputClassName =
    "w-full bg-[#1E1E24]/30 border border-white/10 rounded-lg px-4 py-3.5 text-white caret-[#4CE5E5] [color-scheme:dark] placeholder-white/40 placeholder:font-light focus:outline-none focus:ring-2 focus:ring-[#4CE5E5]/50 focus:border-[#4CE5E5] transition-all duration-300 " +
    "[&:-webkit-autofill]:bg-transparent [&:-webkit-autofill]:[-webkit-text-fill-color:white!important] [&:-webkit-autofill:hover]:[-webkit-text-fill-color:white!important] [&:-webkit-autofill:focus]:[-webkit-text-fill-color:white!important] [&:-webkit-autofill:active]:[-webkit-text-fill-color:white!important] " +
    "[&:-webkit-autofill]:[box-shadow:0_0_0_1000px_#1E1E24_inset!important] [&:-webkit-autofill:hover]:[box-shadow:0_0_0_1000px_#1E1E24_inset!important] [&:-webkit-autofill:focus]:[box-shadow:0_0_0_1000px_#1E1E24_inset!important] [&:-webkit-autofill:active]:[box-shadow:0_0_0_1000px_#1E1E24_inset!important] " +
    "[&:-webkit-autofill]:[transition:background-color_5000s_ease-in-out_0s]";

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
      style={{ colorScheme: "dark" }}
      className="w-full bg-black/20 backdrop-blur-3xl border border-white/15 rounded-xl pt-12 pb-6 px-8 sm:pt-14 sm:pb-7 sm:px-10 shadow-2xl shadow-black/80 overflow-hidden relative [color-scheme:dark]"
    >
      <div className="flex flex-col items-center text-center mb-8">
        <Image
          src="/images/branding/icon.svg"
          alt="HappyPaws Icon"
          width={64}
          height={56}
          className="w-16 h-auto mb-4 drop-shadow-md"
          priority
        />
        <h1 className="text-3xl font-semibold tracking-tight text-white font-outfit mb-2">
          {step === "login" ? "Welcome back" : "Two-factor authentication"}
        </h1>
        <p className="text-[#A0A0B0] text-sm font-light">
          {step === "login"
            ? "Enter your email and password to continue"
            : "Enter the six-digit code sent to your email."}
        </p>
        {step === "otp" && (
          <div className="mt-3 text-xs font-medium bg-[#1E1E24]/50 border border-white/5 py-1.5 px-3 rounded-full">
            {otpExpiresIn > 0 ? (
              <span className="text-[#4CE5E5]/90">
                Code expires in {Math.floor(otpExpiresIn / 60)}:
                {(otpExpiresIn % 60).toString().padStart(2, "0")}
              </span>
            ) : (
              <span className="text-red-400">Code expired. Please resend.</span>
            )}
          </div>
        )}
      </div>

      <AnimatePresence mode="popLayout">
        {error && (
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            className="mb-6 p-4 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-sm"
          >
            {error}
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence mode="popLayout">
        {step === "login" ? (
          <motion.form
            key="login"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
            transition={{ duration: 0.3 }}
            onSubmit={(e) => handleLogin(e, false)}
            style={{ colorScheme: "dark" }}
            className="space-y-5 [color-scheme:dark]"
          >
            <div>
              <label
                htmlFor="email"
                className="block text-xs font-light text-[#A0A0B0] mb-2 uppercase tracking-wider"
              >
                Email address
              </label>
              <input
                id="email"
                type="email"
                autoComplete="username"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Enter your email address"
                style={{ colorScheme: "dark" }}
                className={inputClassName}
              />
            </div>

            <div>
              <label
                htmlFor="password"
                className="block text-xs font-light text-[#A0A0B0] mb-2 uppercase tracking-wider"
              >
                Password
              </label>
              <div className="relative">
                <input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  autoComplete="current-password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  style={{ colorScheme: "dark" }}
                  className={inputClassName}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-white/40 hover:text-white transition-colors p-1"
                  aria-label={showPassword ? "Hide password" : "Show password"}
                >
                  {showPassword ? (
                    <EyeOffIcon className="w-5 h-5" />
                  ) : (
                    <EyeIcon className="w-5 h-5" />
                  )}
                </button>
              </div>
            </div>

            <div className="pt-1">
              <label className="inline-flex items-center gap-3 cursor-pointer select-none group">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="sr-only peer"
                />
                <div
                  className={`w-5 h-5 rounded-md flex items-center justify-center border transition-all duration-200 peer-focus-visible:ring-2 peer-focus-visible:ring-[#4CE5E5]/60 peer-focus-visible:ring-offset-2 peer-focus-visible:ring-offset-[#1E1E24] ${
                    rememberMe
                      ? "bg-[#4CE5E5] border-[#4CE5E5] text-[#1E1E24] shadow-[0_0_12px_rgba(76,229,229,0.35)]"
                      : "bg-[#1E1E24]/50 border-white/20 group-hover:border-white/40"
                  }`}
                >
                  <AnimatePresence>
                    {rememberMe && (
                      <motion.svg
                        key="check"
                        initial={{ scale: 0.5, opacity: 0 }}
                        animate={{ scale: 1, opacity: 1 }}
                        exit={{ scale: 0.5, opacity: 0 }}
                        transition={{ duration: 0.15 }}
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="3.5"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        className="w-3.5 h-3.5 text-[#1E1E24]"
                      >
                        <polyline points="20 6 9 17 4 12" />
                      </motion.svg>
                    )}
                  </AnimatePresence>
                </div>
                <span className="text-sm text-slate-300 font-normal group-hover:text-white transition-colors">
                  Remember me for 30 days
                </span>
              </label>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full mt-4 bg-[#4CE5E5] text-[#1E1E24] font-semibold py-3.5 rounded-lg hover:bg-[#4CE5E5]/90 transition-colors flex items-center justify-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed"
            >
              {isLoading && <LoaderIcon className="w-5 h-5 animate-spin" />}
              <span>{isLoading ? "Logging in..." : "Log in"}</span>
            </button>

            <div className="pt-0.5 text-center">
              <Link
                href="/"
                className="group inline-flex items-center justify-center gap-2 text-sm font-light text-[#A0A0B0] hover:text-white transition-colors py-0.5"
              >
                <ArrowLeftIcon className="w-4 h-4 transition-transform duration-300 ease-out group-hover:-translate-x-1" />
                <span className="transition-colors duration-300">
                  Back to site
                </span>
              </Link>
            </div>
          </motion.form>
        ) : (
          <motion.form
            key="otp"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
            transition={{ duration: 0.3 }}
            onSubmit={handleVerifyOtp}
            className="space-y-5"
          >
            <div>
              <label className="block text-xs font-light text-[#A0A0B0] mb-3 uppercase tracking-wider">
                Verification code
              </label>
              <div className="flex items-center justify-between gap-1.5 sm:gap-2.5 w-full">
                <div className="grid grid-cols-3 gap-1.5 sm:gap-2.5 flex-1">
                  {[0, 1, 2].map((index) => {
                    const value = otpValues[index];
                    const isFocused = focusedIndex === index;
                    return (
                      <motion.input
                        key={index}
                        ref={(el) => {
                          otpRefs.current[index] = el;
                        }}
                        type="text"
                        inputMode="numeric"
                        autoComplete="one-time-code"
                        value={value}
                        onFocus={() => setFocusedIndex(index)}
                        onBlur={() => setFocusedIndex(null)}
                        onChange={(e) => handleOtpChange(index, e.target.value)}
                        onKeyDown={(e) => handleOtpKeyDown(index, e)}
                        onPaste={handleOtpPaste}
                        animate={{
                          scale: isFocused ? 1.05 : 1,
                          y: isFocused ? -2 : 0,
                        }}
                        whileTap={{ scale: 0.96 }}
                        transition={{
                          type: "spring",
                          stiffness: 450,
                          damping: 25,
                        }}
                        className={`w-full aspect-square text-center text-xl sm:text-2xl font-outfit font-semibold rounded-xl backdrop-blur-md caret-transparent select-none transition-all duration-200 text-white focus:outline-none ${
                          isFocused
                            ? "bg-white/[0.12] border-2 border-[#4CE5E5] ring-4 ring-[#4CE5E5]/25 shadow-[0_0_20px_rgba(76,229,229,0.25)]"
                            : value
                              ? "bg-white/[0.08] border border-white/25 shadow-inner"
                              : "bg-white/[0.04] border border-white/10 shadow-[inset_0_1px_1px_rgba(255,255,255,0.1)]"
                        }`}
                      />
                    );
                  })}
                </div>

                <div className="flex items-center justify-center px-0.5 text-white/20 select-none text-xl font-light">
                  •
                </div>

                <div className="grid grid-cols-3 gap-1.5 sm:gap-2.5 flex-1">
                  {[3, 4, 5].map((index) => {
                    const value = otpValues[index];
                    const isFocused = focusedIndex === index;
                    return (
                      <motion.input
                        key={index}
                        ref={(el) => {
                          otpRefs.current[index] = el;
                        }}
                        type="text"
                        inputMode="numeric"
                        autoComplete="one-time-code"
                        value={value}
                        onFocus={() => setFocusedIndex(index)}
                        onBlur={() => setFocusedIndex(null)}
                        onChange={(e) => handleOtpChange(index, e.target.value)}
                        onKeyDown={(e) => handleOtpKeyDown(index, e)}
                        onPaste={handleOtpPaste}
                        animate={{
                          scale: isFocused ? 1.05 : 1,
                          y: isFocused ? -2 : 0,
                        }}
                        whileTap={{ scale: 0.96 }}
                        transition={{
                          type: "spring",
                          stiffness: 450,
                          damping: 25,
                        }}
                        className={`w-full aspect-square text-center text-xl sm:text-2xl font-outfit font-semibold rounded-xl backdrop-blur-md caret-transparent select-none transition-all duration-200 text-white focus:outline-none ${
                          isFocused
                            ? "bg-white/[0.12] border-2 border-[#4CE5E5] ring-4 ring-[#4CE5E5]/25 shadow-[0_0_20px_rgba(76,229,229,0.25)]"
                            : value
                              ? "bg-white/[0.08] border border-white/25 shadow-inner"
                              : "bg-white/[0.04] border border-white/10 shadow-[inset_0_1px_1px_rgba(255,255,255,0.1)]"
                        }`}
                      />
                    );
                  })}
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between text-xs sm:text-sm text-[#A0A0B0] pt-1">
              <span>Didn&apos;t receive the code?</span>
              <button
                type="button"
                onClick={() => handleLogin(undefined, true)}
                disabled={isLoading || resendCountdown > 0}
                className="text-[#4CE5E5] hover:text-[#4CE5E5]/80 font-medium transition-colors disabled:text-[#A0A0B0]/40 disabled:cursor-not-allowed cursor-pointer"
              >
                {resendCountdown > 0
                  ? `Resend in ${resendCountdown}s`
                  : "Resend code"}
              </button>
            </div>

            <button
              type="submit"
              disabled={isLoading || otpValues.join("").length !== 6}
              className="w-full mt-2 bg-[#4CE5E5] text-[#1E1E24] font-semibold py-3.5 rounded-lg hover:bg-[#4CE5E5]/90 transition-colors flex items-center justify-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed cursor-pointer"
            >
              {isLoading && <LoaderIcon className="w-5 h-5 animate-spin" />}
              <span>{isLoading ? "Verifying code..." : "Verify code"}</span>
            </button>

            <div className="pt-2 text-center">
              <button
                type="button"
                onClick={() => {
                  setStep("login");
                  setOtpValues(Array(6).fill(""));
                  setError("");
                }}
                className="group inline-flex items-center justify-center gap-2 text-sm font-light text-[#A0A0B0] hover:text-white transition-colors py-0.5 cursor-pointer"
              >
                <ArrowLeftIcon className="w-4 h-4 transition-transform duration-300 ease-out group-hover:-translate-x-1" />
                <span className="transition-colors duration-300">
                  Back to login
                </span>
              </button>
            </div>
          </motion.form>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
