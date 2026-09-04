import type { Metadata } from "next";
import { Outfit } from "next/font/google";
import "./globals.css";

const outfit = Outfit({
  subsets: ["latin"],
  variable: "--font-outfit",
  weight: ["300", "400", "500", "600", "700", "800"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Happy Paws",
  description: "Happy Paws - Animal Rescue & Rehoming Platform",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${outfit.variable} font-outfit scroll-smooth`}>
      <body className="font-outfit antialiased bg-white text-gray-900">
        {children}
      </body>
    </html>
  );
}
