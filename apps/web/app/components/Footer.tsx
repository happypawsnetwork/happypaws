import Image from "next/image";
import Link from "next/link";

export default function Footer() {
  return (
    <footer className="bg-[#12121A] py-8 border-t border-[#3A3A4A]/40 font-outfit">
      <div className="max-w-7xl mx-auto px-6 sm:px-12 lg:px-16 flex flex-col md:flex-row items-center justify-between gap-6">
        <Link href="/" className="flex items-center">
          <div className="relative h-8 w-36 sm:w-44">
            <Image
              src="/images/branding/logo.svg"
              alt="HappyPaws Logo"
              fill
              className="object-contain object-left"
            />
          </div>
        </Link>

        <div className="text-xs text-[#A0A0B0] font-light text-center">
          &copy; {new Date().getFullYear()} Happy Paws. All rights reserved.
        </div>

        <div className="flex flex-wrap items-center justify-center gap-4 sm:gap-6 text-xs text-[#A0A0B0] font-light">
          <Link href="/privacy" className="hover:text-white transition-colors">
            Privacy Policy
          </Link>
          <Link href="/cookies" className="hover:text-white transition-colors">
            Cookie Policy
          </Link>
          <Link href="/terms" className="hover:text-white transition-colors">
            Terms of Service
          </Link>
        </div>
      </div>
    </footer>
  );
}
