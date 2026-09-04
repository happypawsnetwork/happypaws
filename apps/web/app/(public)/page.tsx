import Image from "next/image";

function IconSparkles(props: React.SVGProps<SVGSVGElement>) {
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
        d="M5 3v4M3 5h4M6 17v4M4 19h4M13 3l2.5 6.5L22 12l-6.5 2.5L13 21l-2.5-6.5L4 12l6.5-2.5L13 3z"
      />
    </svg>
  );
}

function GooglePlayIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      {...props}
    >
      <mask
        id="mask0_87_8320_page"
        style={{ maskType: "alpha" }}
        maskUnits="userSpaceOnUse"
        x="7"
        y="3"
        width="24"
        height="26"
      >
        <path
          d="M30.0484 14.4004C31.3172 15.0986 31.3172 16.9014 30.0484 17.5996L9.75627 28.7659C8.52052 29.4459 7 28.5634 7 27.1663L7 4.83374C7 3.43657 8.52052 2.55415 9.75627 3.23415L30.0484 14.4004Z"
          fill="#C4C4C4"
        />
      </mask>
      <g mask="url(#mask0_87_8320_page)">
        <path
          d="M7.63473 28.5466L20.2923 15.8179L7.84319 3.29883C7.34653 3.61721 7 4.1669 7 4.8339V27.1664C7 27.7355 7.25223 28.2191 7.63473 28.5466Z"
          fill="url(#paint0_linear_87_8320_page)"
        />
        <path
          d="M30.048 14.4003C31.3169 15.0985 31.3169 16.9012 30.048 17.5994L24.9287 20.4165L20.292 15.8175L24.6923 11.4531L30.048 14.4003Z"
          fill="url(#paint1_linear_87_8320_page)"
        />
        <path
          d="M24.9292 20.4168L20.2924 15.8179L7.63477 28.5466C8.19139 29.0232 9.02389 29.1691 9.75635 28.766L24.9292 20.4168Z"
          fill="url(#paint2_linear_87_8320_page)"
        />
        <path
          d="M7.84277 3.29865L20.2919 15.8177L24.6922 11.4533L9.75583 3.23415C9.11003 2.87878 8.38646 2.95013 7.84277 3.29865Z"
          fill="url(#paint3_linear_87_8320_page)"
        />
      </g>
      <defs>
        <linearGradient
          id="paint0_linear_87_8320_page"
          x1="15.6769"
          y1="10.874"
          x2="7.07106"
          y2="19.5506"
          gradientUnits="userSpaceOnUse"
        >
          <stop stopColor="#00C3FF" />
          <stop offset="1" stopColor="#1BE2FA" />
        </linearGradient>
        <linearGradient
          id="paint1_linear_87_8320_page"
          x1="20.292"
          y1="15.8176"
          x2="31.7381"
          y2="15.8176"
          gradientUnits="userSpaceOnUse"
        >
          <stop stopColor="#FFCE00" />
          <stop offset="1" stopColor="#FFEA00" />
        </linearGradient>
        <linearGradient
          id="paint2_linear_87_8320_page"
          x1="7.36932"
          y1="30.1004"
          x2="22.595"
          y2="17.8937"
          gradientUnits="userSpaceOnUse"
        >
          <stop stopColor="#DE2453" />
          <stop offset="1" stopColor="#FE3944" />
        </linearGradient>
        <linearGradient
          id="paint3_linear_87_8320_page"
          x1="8.10725"
          y1="1.90137"
          x2="22.5971"
          y2="13.7365"
          gradientUnits="userSpaceOnUse"
        >
          <stop stopColor="#11D574" />
          <stop offset="1" stopColor="#01F176" />
        </linearGradient>
      </defs>
    </svg>
  );
}

function AppleIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      viewBox="-1.5 0 20 20"
      fill="currentColor"
      xmlns="http://www.w3.org/2000/svg"
      {...props}
    >
      <g
        id="Page-1"
        stroke="none"
        strokeWidth="1"
        fill="none"
        fillRule="evenodd"
      >
        <g
          id="Dribbble-Light-Preview"
          transform="translate(-102.000000, -7439.000000)"
          fill="currentColor"
        >
          <g id="icons" transform="translate(56.000000, 160.000000)">
            <path
              d="M57.5708873,7282.19296 C58.2999598,7281.34797 58.7914012,7280.17098 58.6569121,7279 C57.6062792,7279.04 56.3352055,7279.67099 55.5818643,7280.51498 C54.905374,7281.26397 54.3148354,7282.46095 54.4735932,7283.60894 C55.6455696,7283.69593 56.8418148,7283.03894 57.5708873,7282.19296 M60.1989864,7289.62485 C60.2283111,7292.65181 62.9696641,7293.65879 63,7293.67179 C62.9777537,7293.74279 62.562152,7295.10677 61.5560117,7296.51675 C60.6853718,7297.73474 59.7823735,7298.94772 58.3596204,7298.97372 C56.9621472,7298.99872 56.5121648,7298.17973 54.9134635,7298.17973 C53.3157735,7298.17973 52.8162425,7298.94772 51.4935978,7298.99872 C50.1203933,7299.04772 49.0738052,7297.68074 48.197098,7296.46676 C46.4032359,7293.98379 45.0330649,7289.44985 46.8734421,7286.3899 C47.7875635,7284.87092 49.4206455,7283.90793 51.1942837,7283.88393 C52.5422083,7283.85893 53.8153044,7284.75292 54.6394294,7284.75292 C55.4635543,7284.75292 57.0106846,7283.67793 58.6366882,7283.83593 C59.3172232,7283.86293 61.2283842,7284.09893 62.4549652,7285.8199 C62.355868,7285.8789 60.1747177,7287.09489 60.1989864,7289.62485"
              id="apple-[#173]"
            ></path>
          </g>
        </g>
      </g>
    </svg>
  );
}

export default function Home() {
  return (
    <div className="relative min-h-screen bg-white text-gray-900 font-outfit">
      {/* Hero Section */}
      <section
        id="home"
        className="relative min-h-screen flex flex-col justify-center items-center px-4 sm:px-6 lg:px-8 py-16 overflow-hidden bg-[#1E1E24] text-white"
      >
        {/* Mobile Background Image */}
        <div className="absolute inset-0 md:hidden z-0">
          <Image
            src="/images/hero/hero-mobile.jpg"
            alt="HappyPaws Mobile Hero Background"
            fill
            priority
            sizes="100vw"
            className="object-cover object-center brightness-75"
          />
        </div>

        {/* Desktop Background Image */}
        <div className="absolute inset-0 hidden md:block z-0">
          <Image
            src="/images/hero/hero-desktop.jpg"
            alt="HappyPaws Desktop Hero Background"
            fill
            priority
            sizes="100vw"
            className="object-cover object-center brightness-75"
          />
        </div>

        {/* Dark Gradient Overlay for Maximum Readability */}
        <div className="absolute inset-0 bg-gradient-to-b from-[#1E1E24]/80 via-[#1E1E24]/85 to-[#1E1E24] z-10" />

        {/* Hero Content */}
        <div className="relative z-20 mx-auto max-w-5xl text-center">
          <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-[#4CE5E5]/30 bg-[#2B2B36]/80 px-4 py-1.5 text-xs sm:text-sm font-semibold text-[#4CE5E5] backdrop-blur-md font-outfit">
            <IconSparkles className="h-4 w-4" />
            <span className="font-semibold tracking-wide">
              Welcome to HappyPaws.lk
            </span>
          </div>

          <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl lg:text-7xl text-white leading-tight font-outfit max-w-max mx-auto">
            A verified animal <span className="text-[#4CE5E5]">rescue</span>
            <br />
            <span className="text-[#4CE5E5]">network</span> and{" "}
            <span className="text-[#4CE5E5]">pet community</span>
          </h1>

          <p className="mt-6 font-light text-base sm:text-xl text-[#A0A0B0] max-w-3xl mx-auto px-6 sm:px-0 leading-relaxed font-outfit">
            A friendly neighborhood for pet owners and rescuers in Sri Lanka.
            Share photos, get care advice, and rehome street animals.
          </p>

          {/* Hero App Store & Google Play Badges */}
          <div className="mt-8 sm:mt-10 flex flex-row items-center justify-center gap-3 sm:gap-5">
            {/* Apple App Store Badge */}
            <a
              href="#"
              className="group relative inline-flex items-center gap-2.5 sm:gap-3.5 rounded-xl border border-[#3A3A4A] bg-[#1E1E24]/90 px-3.5 py-2 min-w-[145px] sm:px-5.5 sm:py-2.5 sm:min-w-[195px] shadow-xl shadow-black/40 backdrop-blur-md transition-all duration-300 ease-out hover:border-[#4CE5E5]/70 hover:bg-[#2B2B36] hover:-translate-y-0.5"
            >
              <AppleIcon className="h-6 w-6 sm:h-7 sm:w-7 text-white transition-transform duration-300 ease-out group-hover:scale-110" />
              <div className="flex flex-col text-left leading-none">
                <span className="mt-1 text-[9px] sm:text-[10px] font-normal tracking-tight text-white/80 transition-colors duration-300 group-hover:text-white">
                  Download on the
                </span>
                <span className="text-sm sm:text-lg tracking-tight text-white transition-colors duration-300 group-hover:text-[#4CE5E5] font-outfit">
                  App Store
                </span>
              </div>
            </a>

            {/* Google Play Store Badge */}
            <a
              href="#"
              className="group relative inline-flex items-center gap-2.5 sm:gap-3.5 rounded-xl border border-[#3A3A4A] bg-[#1E1E24]/90 px-3.5 py-2 min-w-[145px] sm:px-5.5 sm:py-2.5 sm:min-w-[195px] shadow-xl shadow-black/40 backdrop-blur-md transition-all duration-300 ease-out hover:border-[#4CE5E5]/70 hover:bg-[#2B2B36] hover:-translate-y-0.5"
            >
              <GooglePlayIcon className="h-6 w-6 sm:h-7 sm:w-7 transition-transform duration-300 ease-out group-hover:scale-110" />
              <div className="flex flex-col text-left leading-none">
                <span className="mt-1 text-[9px] sm:text-[10px] font-normal tracking-tight text-white/80 transition-colors duration-300 group-hover:text-white">
                  GET IT ON
                </span>
                <span className="text-sm sm:text-lg tracking-tight text-white transition-colors duration-300 group-hover:text-[#4CE5E5] font-outfit">
                  Google Play
                </span>
              </div>
            </a>
          </div>
        </div>
      </section>
    </div>
  );
}
