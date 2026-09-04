"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { motion, useScroll, useMotionValueEvent } from "framer-motion";

function MenuIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      viewBox="0 0 24 24"
      xmlns="http://www.w3.org/2000/svg"
      {...props}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M4 6h16M4 12h16M4 18h16"
      />
    </svg>
  );
}

function CloseIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      viewBox="0 0 24 24"
      xmlns="http://www.w3.org/2000/svg"
      {...props}
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M6 18L18 6M6 6l12 12"
      />
    </svg>
  );
}

const navItems = [
  { name: "Home", href: "#home" },
  { name: "About", href: "#about" },
  { name: "Adopt", href: "#adopt" },
  { name: "Community", href: "#community" },
  { name: "Share a story", href: "#share-a-story" },
];

export default function Header() {
  const [hidden, setHidden] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const { scrollY } = useScroll();

  useMotionValueEvent(scrollY, "change", (latest) => {
    const previous = scrollY.getPrevious() ?? 0;

    // Check if scrolled past threshold
    if (latest > 80) {
      setScrolled(true);
    } else {
      setScrolled(false);
    }

    // Hide on scroll down, show on scroll up
    if (latest > previous && latest > 150) {
      setHidden(true);
    } else {
      setHidden(false);
    }
  });

  return (
    <motion.header
      variants={{
        visible: { y: 0 },
        hidden: { y: "-100%" },
      }}
      animate={hidden ? "hidden" : "visible"}
      transition={{ duration: 0.35, ease: "easeInOut" }}
      className={`fixed top-0 left-0 right-0 z-50 transition-colors duration-300 ${
        scrolled
          ? "bg-[#1E1E24]/90 backdrop-blur-md border-b border-[#3A3A4A]/60 py-4 shadow-lg shadow-black/20"
          : "bg-transparent py-7"
      }`}
    >
      <div className="w-full px-6 sm:px-12 lg:px-16 flex items-center justify-between">
        {/* Left Section: Logo + Nav Items */}
        <div className="flex items-center gap-8 md:gap-12">
          {/* Logo */}
          <Link href="/" className="flex items-center">
            <div className="relative h-10 w-40 sm:w-48">
              <Image
                src="/images/branding/logo.svg"
                alt="HappyPaws Logo"
                fill
                className="object-contain object-left"
                priority
              />
            </div>
          </Link>

          {/* Desktop Nav Items */}
          <nav className="hidden md:flex items-center gap-6 sm:gap-8">
            {navItems.map((item) => (
              <Link
                key={item.name}
                href={item.href}
                className="text-sm font-medium text-white/80 hover:text-[#4CE5E5] transition-colors relative py-1 group"
              >
                {item.name}
                <span className="absolute bottom-0 left-0 w-0 h-0.5 bg-[#4CE5E5] transition-all duration-200 group-hover:w-full" />
              </Link>
            ))}
          </nav>
        </div>

        {/* Rightmost CTA: Apple-style Minimal Translucent Capsule Button */}
        <div className="hidden sm:flex items-center">
          <motion.div
            whileTap={{ scale: 0.95 }}
            transition={{ type: "spring", stiffness: 400, damping: 15 }}
          >
            <Link
              href="#"
              className="inline-flex items-center justify-center rounded-full bg-[#4CE5E5] px-6 py-2.5 text-xs font-semibold text-[#1E1E24] transition-all duration-300 ease-out hover:bg-[#4CE5E5]/90 hover:-translate-y-0.5"
            >
              <span>Get the App</span>
            </Link>
          </motion.div>
        </div>

        {/* Mobile Menu Button */}
        <div className="flex md:hidden items-center gap-2">
          <motion.div
            whileTap={{ scale: 0.95 }}
            transition={{ type: "spring", stiffness: 400, damping: 15 }}
          >
            <Link
              href="#"
              className="inline-flex items-center justify-center rounded-full bg-[#4CE5E5] px-4 py-2 text-xs font-semibold text-[#1E1E24] transition-colors duration-300 hover:bg-[#4CE5E5]/90"
            >
              <span>App</span>
            </Link>
          </motion.div>
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="p-2 rounded-lg text-white hover:bg-[#2B2B36] transition-colors"
            aria-label="Toggle Navigation Menu"
          >
            {mobileMenuOpen ? (
              <CloseIcon className="h-6 w-6" />
            ) : (
              <MenuIcon className="h-6 w-6" />
            )}
          </button>
        </div>
      </div>

      {/* Mobile Dropdown Menu */}
      {mobileMenuOpen && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: "auto" }}
          exit={{ opacity: 0, height: 0 }}
          className="md:hidden bg-[#1E1E24]/95 backdrop-blur-lg border-b border-[#3A3A4A] px-6 pt-3 pb-6"
        >
          <div className="flex flex-col gap-3">
            {navItems.map((item) => (
              <Link
                key={item.name}
                href={item.href}
                onClick={() => setMobileMenuOpen(false)}
                className="text-base font-medium text-white/90 hover:text-[#4CE5E5] py-2 border-b border-[#2B2B36]"
              >
                {item.name}
              </Link>
            ))}
          </div>
        </motion.div>
      )}
    </motion.header>
  );
}
