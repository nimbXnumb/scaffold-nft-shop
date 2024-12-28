"use client";

import Image from "next/image";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { Address } from "~~/components/scaffold-eth";

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center">
            <span className="block text-2xl mb-2">Добро пожаловать!</span>
            <span className="block text-4xl font-bold">So-Good-NFT</span>
          </h1>
          <div className="flex justify-center items-center space-x-2 flex-col sm:flex-row">
            <p className="my-2 font-medium">Ваш адрес:</p>
            <Address address={connectedAddress} />
          </div>
          <p className="text-center text-lg">
            У нас вы можете получить любой NFT из большой коллекции, если сделаете ставку больше остальных участников!
          </p>
          <p className="text-center text-lg">Регулярные акции и аукционы, получите всё что захотите!</p>
        </div>

        <Image src={require("./images/piture1.png")} alt="NFT 1" className="h-32 w-32 object-contain" />

        <div className="flex-grow bg-base-300 w-full mt-16 px-8 py-12">
          <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <Image src={require("./images/picture2.png")} alt="NFT 2" className="h-32 w-32 object-contain" />
              <p>NFT на любой вкус и цвет.</p>
            </div>
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <Image src={require("./images/picture3.png")} alt="NFT 3" className="h-32 w-32 object-contain" />
              <p>Получите стильные NFT!</p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
